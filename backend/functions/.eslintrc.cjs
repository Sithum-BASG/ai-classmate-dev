module.exports = {
  root: true,
  env: { es2022: true, node: true },
  parserOptions: { ecmaVersion: 2022, sourceType: 'module' },
  plugins: ['import'],
  extends: ['eslint:recommended', 'plugin:import/recommended', 'prettier'],
  rules: {
    'import/order': [
      'warn',
      {
        'newlines-between': 'always',
        alphabetize: { order: 'asc', caseInsensitive: true }
      }
    ]
  }
};

