# epilepsy-ecg
EpiHeartMonitor app that streams ECG data transmitted by Movesense MD sensor.

## Installation

1. Clone repo
2. Allow SPM packages to resolve
3. Run the project

## Codebase

The app is build in SwiftUI using MVVM architecture. The data is contained in the ViewModels that interacts with Clients. The overall structure is very modularized using Swift Packages for features and dependencies. Dependencies are modelled as structs. Point-Free libraries are used for dependency injection. 

Additionally, to interact with the Movesense-MD device, @mikkojeronen MovesenseApi-iOS library was utilized.

*Use feature/MovesenseIntegration branch to clone.
