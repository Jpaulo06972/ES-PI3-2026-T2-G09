module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:import/errors",
    "plugin:import/warnings",
    "plugin:import/typescript",
    "google",
    "plugin:@typescript-eslint/recommended",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    tsconfigRootDir: __dirname,
    project: ["tsconfig.json", "tsconfig.dev.json"],
    sourceType: "module",
  },
  ignorePatterns: [
    "/lib/**/*", // Ignore built files.
    "/generated/**/*", // Ignore generated files.
  ],
  plugins: [
    "@typescript-eslint",
    "import",
  ],
  rules: {
    "quotes": "off",
    "import/no-unresolved": 0,
    "indent": "off",
    "linebreak-style": "off",
    "require-jsdoc": "off",
    "max-len": "off",
    "object-curly-spacing": "off",
    "comma-dangle": "off",
    "no-trailing-spaces": "off",
    "eol-last": "off",
    "padded-blocks": "off",
    "arrow-parens": "off",
    "spaced-comment": "off",
    "no-multiple-empty-lines": "off",
    "@typescript-eslint/no-unused-vars": "off",
    "@typescript-eslint/no-explicit-any": "off",
  },
};
