flowchart TD

A[App Launch] --> B{Choose Option}

B -->|Create Room| C[Create Game Room]
B -->|Join Room| D[Enter Game ID]

C --> E[Create Game Document in Firestore]
D --> F[Find Game by ID]

F --> G{Room Exists?}
G -->|No| H[Show Error]
G -->|Yes| I[Join Room]

E --> J[Enter Waiting Room]
I --> J

J --> K[Players Join Room]

K --> L{Host Actions}

L -->|Add Bot| M[Host Adds Bot Player]
M --> K

L -->|Wait for Players| K

K --> N{Enough Players to Start}

N -->|No| L
N -->|Yes| O[Host Starts Game]

O --> P[Initialize Deck]
P --> Q[Deal 2 Influence Cards to Each Player]
Q --> R[Set First Turn Player]

R --> S[Game Start]

S --> T[Turn Begins]

T --> U{Current Player Select Action}

U --> V[Create Action in Firestore]

V --> W{Any Player Challenge}

W -->|Yes| X[Challenge Phase]
W -->|No| Y{Target Block}

X --> Z[Resolve Challenge]

Z --> AA{Challenge Successful}

AA -->|Yes| AB[Action Cancelled]
AA -->|No| Y

Y -->|Yes| AC[Block Phase]
Y -->|No| AD[Resolve Action]

AC --> AE{Block Challenged}

AE -->|Yes| AF[Resolve Block Challenge]
AE -->|No| AB

AF --> AG{Block Valid}

AG -->|Yes| AB
AG -->|No| AD

AD --> AH[Apply Action Effects]

AH --> AI{Target Lost Influence}

AI -->|Yes| AJ[Reveal Influence]

AJ --> AK{Player Eliminated}

AK -->|Yes| AL[Check Remaining Players]
AK -->|No| AL

AL --> AM{Only One Player Alive}

AM -->|Yes| AN[Game Finished]
AM -->|No| AO[Next Player Turn]

AO --> T

AN --> AP[Show Winner]

AP --> AQ[Return to Lobby]