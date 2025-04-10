module.exports = {
  env: {
    node: true,
    es2020: true,
  },
  extends: [
    "eslint:recommended",
    "google"
  ],
  parserOptions: {
    ecmaVersion: 2020,
  },
  rules: {
    "no-undef": "off",
    "quotes": ["error", "double"],
    "indent": ["error", 2],
    "require-jsdoc": "off",
    "max-len": ["error", { "code": 120 }],
  },
  globals: {
    process: "readonly"
  }
};
