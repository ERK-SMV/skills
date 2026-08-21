---
name: diagram-type-guide
description: "Select UML diagram types for visualization needs."
version: 1.0.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [uml, diagrams, plantuml, architecture, design]
    related_skills: [plantuml, architecture-diagram, concept-diagrams]
---

# UML Diagram Type Selection Guide

## 🎯 Overview

Guide for selecting the most appropriate UML diagram type based on use case and visualization requirements.

## 📋 Quick Selection Guide

| Use Case | Recommended Diagram | When to Use |
|----------|-------------------|--------------|
| Repository structures, system components | Component Diagram | Static structures with properties
| Process flows, API interactions | Sequence Diagram | Temporal sequences and interactions
| Class hierarchies, OOP design | Class Diagram | Object-oriented relationships
| State transitions, lifecycles | State Diagram | State-based behavior
| Business processes, workflows | Activity Diagram | Process flows with decisions

## 🚨 Key Learning

**Important Insight**: Sequence diagrams are NOT appropriate for showing static repository structures. Component diagrams are much better suited for this purpose.

### Why Component Diagrams for Repository Structures?
- Show static structures with properties
- Support visual distinction (public/private repositories)
- Clearly represent component relationships
- Better for architectural documentation

### When Sequence Diagrams Are Appropriate
- Showing temporal flow and interactions
- API call sequences
- Workflow processes with timing
- Emphasizing order of operations

## 📝 Component Diagram Example

```plantuml
@startuml GitHub_Repository_Structure

title GitHub Management Repository Proposal

skinparam component {
    BackgroundColor<<Public>> #AAAAFF
    BackgroundColor<<Private>> #FFAAAA
}

package "GitHub Repositories" {
    component "RFE" <<Public>> {
        Status: public
        Default Branch: main
        Content: Facturx/CII/UBL/CDAR/E-reporting
        Testing: 2 factures pour chaque schematron
    }
    
    component "FNFE-WIP" <<Private>> {
        Status: privée
        Default Branch: tes branches à toi
        Content: (empty)
        Testing: 2 factures pour chaque schematron
    }
}

[User] --> RFE : Manages
[User] --> FNFE-WIP : Manages

legend right
    | Repository Types |
    <back:AAAAFF> Public Repository
    <back:FFAAAA> Private Repository
    
    Common Requirements:
    - 2 test invoices per schematron
    - User has full release control
endlegend

@enduml
```

## ✅ Best Practices

1. **Match diagram type to purpose**
   - Component diagrams for "what exists"
   - Sequence diagrams for "what happens"

2. **Use visual distinction**
   - Color coding for different types
   - Consistent layout patterns

3. **Keep diagrams focused**
   - One main idea per diagram
   - Use legends for context

4. **Validate before use**
   - Check PlantUML syntax
   - Verify rendering

## 📚 References

- PlantUML component diagram documentation
- UML diagram type comparisons
- Visualization best practices