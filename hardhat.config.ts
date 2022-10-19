import { HardhatUserConfig } from "hardhat/config";
import "tsconfig-paths/register";

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.9",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.13"
      }
    ]
  },
};

export default config;
