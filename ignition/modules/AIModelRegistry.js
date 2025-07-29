const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("AIModelRegistryModule", (m) => {
  const aiModelRegistry = m.contract("AIModelRegistry");
  return { aiModelRegistry };
});
