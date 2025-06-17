import type { Plugin } from "@elizaos/core-plugin-v1";
import { ignoreAction } from "./actions/ignore.ts";

export * as actions from "./actions/index.ts";
export * as evaluators from "./evaluators/index.ts";
export * as providers from "./providers/index.ts";

export const web3Plugin: Plugin = {
    name: "web3",
    description: "Agent plugin with web3 interactions",
    actions: [],
    evaluators: [],
    providers: [],
};
export default web3Plugin;
