#!/usr/bin/env python3
"""
Odoo MCP Server - Main implementation
Handles MCP protocol requests and routes them to Odoo
"""

import os
import logging
from dotenv import load_dotenv
from functools import lru_cache
from typing import Dict, Any, List

from mcp_server import MCPServer, MCPRequest, MCPResponse
from odoorpc import ODOO

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=os.getenv('LOG_LEVEL', 'INFO'),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class OdooMCPConfig:
    """Configuration for Odoo MCP Server"""
    ODOO_HOST = os.getenv('ODOO_HOST', 'odoo-service')
    ODOO_PORT = int(os.getenv('ODOO_PORT', '8069'))
    ODOO_DB = os.getenv('ODOO_DB', 'your_database')
    ODOO_USER = os.getenv('ODOO_USER', 'admin')
    ODOO_PASSWORD = os.getenv('ODOO_PASSWORD', '')
    
    MCP_HOST = os.getenv('MCP_HOST', '0.0.0.0')
    MCP_PORT = int(os.getenv('MCP_PORT', '3000'))
    
    CONNECTION_POOL_SIZE = int(os.getenv('CONNECTION_POOL_SIZE', '10'))
    REQUEST_TIMEOUT = int(os.getenv('REQUEST_TIMEOUT', '60'))

class OdooMCPServer(MCPServer):
    """Odoo MCP Server implementation"""
    
    def __init__(self):
        super().__init__()
        self.config = OdooMCPConfig()
        logger.info("Odoo MCP Server initializing...")
        logger.info(f"Odoo: {self.config.ODOO_HOST}:{self.config.ODOO_PORT}")
        logger.info(f"MCP: {self.config.MCP_HOST}:{self.config.MCP_PORT}")
    
    @lru_cache(maxsize=OdooMCPConfig.CONNECTION_POOL_SIZE)
    def _get_odoo_connection(self) -> ODOO:
        """Get Odoo connection with caching"""
        try:
            odoo = ODOO(
                self.config.ODOO_HOST,
                port=self.config.ODOO_PORT,
                timeout=self.config.REQUEST_TIMEOUT
            )
            odoo.login(
                self.config.ODOO_DB,
                self.config.ODOO_USER,
                self.config.ODOO_PASSWORD
            )
            logger.info("Odoo connection established successfully")
            return odoo
        except Exception as e:
            logger.error(f"Failed to connect to Odoo: {str(e)}")
            raise
    
    def handle_request(self, request: MCPRequest) -> MCPResponse:
        """Handle MCP requests and route to Odoo"""
        method = request.method
        params = request.params or {}
        
        logger.debug(f"Received MCP request: {method}")
        logger.debug(f"Params: {params}")
        
        try:
            # Route to appropriate handler
            if method == "odoo/search_read":
                result = self._search_read(params)
            elif method == "odoo/create":
                result = self._create(params)
            elif method == "odoo/write":
                result = self._write(params)
            elif method == "odoo/unlink":
                result = self._unlink(params)
            elif method == "odoo/health":
                result = self._health_check()
            else:
                return MCPResponse.error(f"Method not found: {method}")
            
            logger.debug(f"Request successful, returning {len(result)} records")
            return MCPResponse.success(result)
            
        except Exception as e:
            logger.error(f"Error processing request: {str(e)}", exc_info=True)
            return MCPResponse.error(f"Odoo MCP Error: {str(e)}")
    
    def _search_read(self, params: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Search and read records from Odoo"""
        model = params.get('model')
        domain = params.get('domain', [])
        fields = params.get('fields', [])
        limit = params.get('limit', 100)
        offset = params.get('offset', 0)
        
        if not model:
            raise ValueError("Missing required parameter: model")
        
        logger.info(f"Searching {model} with domain: {domain}")
        
        odoo = self._get_odoo_connection()
        return odoo.env[model].search_read(domain, fields, limit=limit, offset=offset)
    
    def _create(self, params: Dict[str, Any]) -> int:
        """Create new record in Odoo"""
        model = params.get('model')
        values = params.get('values', {})
        
        if not model:
            raise ValueError("Missing required parameter: model")
        if not values:
            raise ValueError("Missing required parameter: values")
        
        logger.info(f"Creating record in {model}")
        
        odoo = self._get_odoo_connection()
        record = odoo.env[model].create(values)
        
        logger.info(f"Created record with ID: {record.id}")
        return record.id
    
    def _write(self, params: Dict[str, Any]) -> bool:
        """Update records in Odoo"""
        model = params.get('model')
        ids = params.get('ids', [])
        values = params.get('values', {})
        
        if not model:
            raise ValueError("Missing required parameter: model")
        if not ids:
            raise ValueError("Missing required parameter: ids")
        if not values:
            raise ValueError("Missing required parameter: values")
        
        logger.info(f"Updating {len(ids)} records in {model}")
        
        odoo = self._get_odoo_connection()
        records = odoo.env[model].browse(ids)
        result = records.write(values)
        
        logger.info(f"Updated {len(records)} records")
        return result
    
    def _unlink(self, params: Dict[str, Any]) -> bool:
        """Delete records from Odoo"""
        model = params.get('model')
        ids = params.get('ids', [])
        
        if not model:
            raise ValueError("Missing required parameter: model")
        if not ids:
            raise ValueError("Missing required parameter: ids")
        
        logger.info(f"Deleting {len(ids)} records from {model}")
        
        odoo = self._get_odoo_connection()
        records = odoo.env[model].browse(ids)
        result = records.unlink()
        
        logger.info(f"Deleted {len(records)} records")
        return result
    
    def _health_check(self) -> Dict[str, Any]:
        """Health check endpoint"""
        try:
            # Test Odoo connection
            odoo = self._get_odoo_connection()
            odoo.env['res.users'].search([], limit=1)
            
            return {
                'status': 'ok',
                'message': 'Odoo MCP Server healthy',
                'odoo_version': self._get_odoo_version()
            }
        except Exception as e:
            return {
                'status': 'error',
                'message': str(e)
            }
    
    def _get_odoo_version(self) -> str:
        """Get Odoo version"""
        try:
            odoo = self._get_odoo_connection()
            return odoo.version
        except:
            return 'unknown'

if __name__ == "__main__":
    # Clear connection cache on startup
    if hasattr(OdooMCPServer._get_odoo_connection, 'cache_clear'):
        OdooMCPServer._get_odoo_connection.cache_clear()
    
    # Start server
    server = OdooMCPServer()
    server.run(
        host=OdooMCPConfig.MCP_HOST,
        port=OdooMCPConfig.MCP_PORT
    )
