export const businessRoles = ['Administrator', 'Operator'] as const;

export type BusinessRole = (typeof businessRoles)[number];
