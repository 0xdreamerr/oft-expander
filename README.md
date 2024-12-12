# Automatically Expanding Omnichain Systems (Alpha verison)

## Based on MIP-01

### Flowchart of token expanding

```mermaid
flowchart TB
    D[Developer] --> |Request to expand OFT to target chain| E

    subgraph ChainA[Source Chain]
        O[OFT]
        E[Omnichain Expander]
        L[LzEndpoint]
        M[MinimalProxy]

        E --> |"tokenInfo()"| M
        M --> |DelegateCall|O
        M --> |Info| E
        E --> |"setPeer()"| M
        E --> |Send tokenInfo| L
    end

    L --> LB

    subgraph ChainB[Target Chain]
        direction TB
        OB[OFT]
        MP[MinimalProxy]
        EB[Omnichain Expander]
        LB[LzEndpoint]

        LB --> |tokenInfo| EB
        EB --> |Deploy deterministically| MP
        MP --> |Delegate Call|OB
        EB --> |"setPeer()"| MP
    end
```

### Creating an OFT based on the MinimalProxy pattern

```mermaid
sequenceDiagram
participant Developer

    box Source Chain
    participant Expander
    participant MinimalProxy as Minimal Proxy
    participant ImplementationOFT
    end


    Developer->>+Expander: createOFT(owner, name, symbol, []allocation)
    Expander->>+MinimalProxy: Creating Minimal Proxy
    MinimalProxy->>ImplementationOFT: init(owner, name, symbol, []allocation)
    ImplementationOFT->>MinimalProxy: write in storage
    MinimalProxy-->>Developer: OFTAddress
```

### Expanding to other chain

```mermaid
    sequenceDiagram
    participant Developer

    box Source Chain
    participant Expander
    participant Minimal Proxy
    participant OFT
    end


    Developer->>OFT: create OFT
    Developer->>OFTt: create OFT
    Developer->>Expander: create Expander
    Developer->>TargetExpander: create Expander
    Developer->>Expander: setPeer(TargetExpander)
    Developer->>TargetExpander: setPeer(Expander)
    Developer->>Expander: expandToken(chainId)
    Expander->>Minimal Proxy: tokenInfo()
    Minimal Proxy-->>Expander: name, symbol, owner

    Expander->>TargetExpander: lzSend(owner, name, symbol)
    TargetExpander->>MinimalProxy: Creating Minimal Proxy
    MinimalProxy->>OFTt: init(owner, name, symbol)
    OFTt -->> MinimalProxy: OFT created
    MinimalProxy -->> Developer: OFT Address
    Developer->>OFTt: setPeer(OFT)
    Developer->>OFT: setPeer(TargetOFT)


    box Target Chain
    participant MinimalProxy
    participant TargetExpander
    participant OFTt

    end
```

### Class diagram

```mermaid
classDiagram
    class Developer {
    }

    class Expander {
        -implementationOFT : address
        -lzEndpoint : address
        +expandToken(chainId)
        +createOFT(owner, supply, name, allocation, symbol)
        +setPeer(TargetExpander)
        +lzReceive()
        +lzSend()
    }

    class MinimalProxy {
        -implementation : address
        -lzEndpoint : address
        +delegateCall(data : bytes)
    }

    class ImplementationOFT {
        -name : string
        -owner : address
        -users : address[]
        -amounts: uint[]
        -symbol: string
        +init(owner, supply, name, allocation, symbol)
        +transfer()
        +setPeer(TargetOFT)
        +lzSend()
        +lzReceive()
        +tokenInfo()
    }

    Developer --> Expander : "2. Deploy Expander"
    Developer --> ImplementationOFT : "1. Deploy OFT"
    Developer --> Expander : "3. Requests creation of OFT"
    Expander <|--|> MinimalProxy : "createOFT()"
    MinimalProxy <|--|> ImplementationOFT : "Delegate call"
```
