# Skill Relations

Architecture diagram showing the three-layer skill system and dependency relationships.

```mermaid
graph TB
    subgraph Standalone["Standalone Skills"]
        WW["writing-well"]
        PR["plan-review"]
    end

    subgraph Domain["Domain Skills"]
        WR["web-research"]
        CR["competitor-research"]
        RCG["researching-consumer-goods"]
    end

    subgraph Infrastructure["Infrastructure Skills"]
        WTR["web-tool-routing"]
        PC["prompt-creator"]
        P74["prompt-74"]
    end

    %% Domain → Infrastructure invocations
    WR -->|"invokes"| WTR
    CR -->|"invokes"| WTR
    RCG -->|"invokes"| WTR
    RCG -.->|"Path B"| PC
    RCG -->|"invokes"| P74

    %% Infrastructure → Infrastructure
    P74 -->|"invokes"| PC

    %% Styling
    style WTR fill:#4a9eff,stroke:#2670c2,color:#fff
    style PC fill:#4a9eff,stroke:#2670c2,color:#fff
    style P74 fill:#4a9eff,stroke:#2670c2,color:#fff
    style WR fill:#50c878,stroke:#2e8b57,color:#fff
    style CR fill:#50c878,stroke:#2e8b57,color:#fff
    style RCG fill:#50c878,stroke:#2e8b57,color:#fff
    style WW fill:#ffa64d,stroke:#cc7a30,color:#fff
    style PR fill:#ffa64d,stroke:#cc7a30,color:#fff
```

## Legend

- **Blue (Infrastructure):** Shared capabilities invoked by domain skills at runtime via the Skill tool
- **Green (Domain):** Research/analysis skills that invoke infrastructure + add domain-specific logic and overrides
- **Orange (Standalone):** Independent skills with no cross-skill dependencies
- **Solid arrows:** "invokes at runtime via Skill tool"
- **Dashed arrows:** conditional invocation (only on specific paths)
