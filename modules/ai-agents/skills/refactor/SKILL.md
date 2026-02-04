---
name: refactor
description: Guide systematic code and architecture refactoring with emphasis on maintainability, design patterns, and code quality. Use this skill when the user asks to refactor code, improve code structure, apply design patterns, eliminate code smells, modularize components, or enhance code maintainability. Triggers include requests like "refactor this module", "this code has code smells", "improve this class design", "split into independent modules", or "make this code more maintainable".
---

# Code Refactoring

Guide systematic refactoring of code and architecture while preserving behavior. Focus on improving maintainability, readability, and design quality.

## Workflow

Follow this incremental process for every refactoring task:

### 1. Analyze

Examine the code to identify:
- **Code smells**: Patterns indicating deeper problems
- **Structural issues**: Coupling, cohesion, responsibility violations
- **Design opportunities**: Where patterns could improve structure

Present findings with specific evidence from the code.

### 2. Plan

Propose a refactoring plan with:
- **Rationale**: Why each change improves the code
- **Steps**: Ordered sequence of atomic refactoring operations
- **Risks**: Potential issues and mitigation strategies

Each step should be small enough to verify independently.

### 3. Confirm

Present the plan to the user. Wait for approval before proceeding.

For significant refactors, offer alternatives:
- Conservative approach (minimal changes)
- Moderate approach (balanced risk/reward)
- Aggressive approach (comprehensive restructure)

### 4. Implement

Execute refactoring in small, verifiable steps:
- Apply one refactoring technique at a time
- Verify behavior preservation after each step
- Provide before/after comparisons for clarity

## Code Smell Detection

Identify these common code smells and their refactoring solutions:

### Shotgun Surgery
**Symptom**: A single change requires modifications across many classes/modules.
**Cause**: Related behavior scattered across the codebase.
**Solutions**:
- Move Method/Field to consolidate related code
- Extract Class to group related functionality
- Apply Facade pattern to provide unified interface

### Divergent Change
**Symptom**: One class/module changes for multiple unrelated reasons.
**Cause**: Violation of Single Responsibility Principle.
**Solutions**:
- Extract Class to separate concerns
- Split module by responsibility
- Apply Strategy pattern for varying behaviors

### Duplicated Code
**Symptom**: Same or similar code in multiple locations.
**Cause**: Copy-paste programming, lack of abstraction.
**Solutions**:
- Extract Method for duplicated logic
- Extract Superclass/Interface for shared behavior
- Apply Template Method pattern for similar algorithms

### Feature Envy
**Symptom**: A method uses more features of another class than its own.
**Cause**: Misplaced responsibility.
**Solutions**:
- Move Method to the class it envies
- Extract and move the envious portion
- Reconsider class boundaries

## Refactoring Techniques

Apply these atomic refactoring operations:

### Extract Method
When: Long method, duplicated code, comments explaining code blocks.
```
// Before: Long method with comment
function process(data) {
  // validate input
  if (!data) throw new Error('...');
  if (!data.id) throw new Error('...');
  // ... more validation
  
  // transform data
  // ... transformation logic
}

// After: Extracted methods
function process(data) {
  validateInput(data);
  return transformData(data);
}
```

### Extract Class
When: Class has too many responsibilities, subset of fields/methods form a logical unit.

### Move Method/Field
When: Method/field is more related to another class, feature envy detected.

### Replace Conditional with Polymorphism
When: Same conditional structure repeats, type-based switching.
```
// Before: Type switching
function getArea(shape) {
  switch(shape.type) {
    case 'circle': return Math.PI * shape.r ** 2;
    case 'rectangle': return shape.w * shape.h;
  }
}

// After: Polymorphism
class Circle { getArea() { return Math.PI * this.r ** 2; } }
class Rectangle { getArea() { return this.w * this.h; } }
```

### Introduce Parameter Object
When: Multiple parameters always travel together.

### Replace Magic Numbers/Strings with Constants
When: Literal values with unclear meaning appear in code.

## Architecture Refactoring

For larger structural changes:

### Modularization
- Identify cohesive functionality groups
- Define clear module boundaries and interfaces
- Minimize inter-module dependencies
- Consider dependency direction (depend on abstractions)

### Layer Separation
- Separate presentation, business logic, and data access
- Enforce unidirectional dependencies between layers
- Use dependency inversion for flexibility

### Interface Extraction
- Identify implicit contracts between components
- Extract explicit interfaces for flexibility
- Enable substitution and testing

## Design Pattern Application

Apply patterns when they solve specific problems:

**Creational**: Factory (object creation complexity), Builder (complex construction), Singleton (global access point)

**Structural**: Adapter (interface mismatch), Facade (complex subsystem), Decorator (dynamic behavior extension), Composite (tree structures)

**Behavioral**: Strategy (algorithm variation), Observer (event notification), Command (action encapsulation), State (state-dependent behavior)

**IMPORTANT**: Never apply patterns preemptively. Identify the problem first, then select the pattern that addresses it.

## Output Format

For each refactoring, provide:

### Analysis
```
Code Smell: [Identified smell]
Location: [File/class/method]
Evidence: [Specific code patterns observed]
Impact: [How this affects maintainability]
```

### Refactoring Plan
```
Goal: [What the refactoring achieves]
Technique: [Primary refactoring method]
Steps:
1. [First atomic step]
2. [Second atomic step]
...
Risks: [Potential issues]
```

### Before/After Comparison
Show the transformed code with explanatory comments highlighting key changes.

## Safety Guidelines

- **Preserve behavior**: Refactoring must not change external behavior
- **Small steps**: Each change should be independently verifiable
- **Test coverage**: Recommend tests before refactoring when missing
- **Rollback plan**: Ensure changes can be reverted if issues arise
- **Document assumptions**: Note any assumptions about unchanged behavior
