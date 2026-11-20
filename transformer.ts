import type { ExpoBabelCaller } from '@expo/metro-config/babel-transformer';

export const caller: ExpoBabelCaller = { name: 'metro', platform: 'ios', projectRoot: '.' };
