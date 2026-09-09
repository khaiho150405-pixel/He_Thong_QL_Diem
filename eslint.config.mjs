import tseslint from "typescript-eslint";
export default tseslint.config(
  { ignores: ["**/dist/**", "**/generated/**", "**/node_modules/**"] },
  ...tseslint.configs.recommended,
  {
    files: ["**/*.ts"],
    rules: {
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/no-empty-object-type": "off",
    },
  },
  {
    files: ["**/domain/**/*.ts"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            "@nestjs/*",
            "@prisma/*",
            "**/infrastructure/*",
            "**/presentation/*",
          ],
        },
      ],
    },
  },
);
