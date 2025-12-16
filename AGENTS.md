# Repository Guidelines

## Project Structure & Module Organization
Core Solidity sources live in `contracts/`; `contracts-EVM/` hosts upgradeable adapters and `contracts-others/` keeps experiments out of main builds. Interface bundles and versioned ABIs sit in `interfacesAll/` and `wikitruth-v1/`; generated `artifacts/` and `typechain-types/` are read-only outputs from Hardhat. Operational assets live in `scripts/` (token-testnet and wikiTruth deploy flows), `tasks/index.ts` (CLI commands), `ignition/` (deterministic provisioning), and `deployments/*.json` (network address manifests). Tests live under `test/test-EVM`, `test/single`, `test/utils`, plus Sapphire helpers documented in `test/README.md`.

## Build, Test, and Development Commands
- `pnpm install` - install Hardhat, Sapphire, and TypeChain toolchains.
- `pnpm hardhat compile` - compile Solidity 0.5-0.8 with via-IR and refresh generated folders.
- `pnpm hardhat test test/test-EVM/*.js` - run the JS/Mocha regression suite.
- `pnpm forge test -vv --match-test TruthBox` - execute Foundry fuzz/property tests using `foundry.toml`.
- `pnpm hardhat run scripts/wikiTruth-testnet/deploy.ts --network sapphire_testnet` - replay the canonical deployment; use `pnpm hardhat send-ping --ping-addr <addr>` for the OPL flow.

## Coding Style & Naming Conventions
Use SPDX headers and 4-space indentation in Solidity; keep contracts/interface names `PascalCase`, functions/events `camelCase`, and constants `SCREAMING_SNAKE_CASE`. TypeScript/JavaScript (configs, tasks, utils) remain 2 spaces with named exports; describe files after the feature (`TruthNFT.manager.ts`) to aid code search. Never edit `artifacts/` or `typechain-types/` manually; regenerate via compile and share helpers under `utils/` instead of duplicating them.

## Testing Guidelines
Hardhat suites rely on fixtures from `@nomicfoundation/hardhat-toolbox`; keep describes scoped to one contract and adopt `should_<action>` statements. Sapphire/SIWE helpers in `test/utils` manage token generation, so import `generateSiweAuthTokens` rather than re-implementing auth flows. When behavior touches funds or cross-chain messaging, add a Foundry invariant test plus at least one scenario in `test/diagnostic/`.

## Commit & Pull Request Guidelines
The working copy ships without `.git`, but the upstream history follows Conventional Commits; confirm with `git log --oneline -15` in the canonical repo and match `type(scope): summary` with imperative verbs. Reference an issue ID, explain the change, and note any ABI or deployment JSON updates. PRs must list test commands, affected networks, and link to the updated files under `deployments/` or `scripts/`.

## Security & Configuration Tips
Secrets belong in `.env`; expect `ADMIN_PRIVATE_KEY_EVM`, `MINTER_PRIVATE_KEY_EVM`, and demo keys from the README. Never commit `.env`, the `private/` folder, or live RPC URLs; rotate credentials if they hit a shared paste. Use `hardhat-switch-network` or explicit `--network` flags so tasks read the correct endpoints, and document any new environment variables or signing requirements for the next agent.
