import { useColorScheme } from 'react-native';

export const lightPalette = {
  mode: 'light' as const,
  background: '#F5F6F1',
  surface: '#FFFFFF',
  surfaceRaised: '#FFFFFF',
  surfaceTint: '#EAF0E9',
  text: '#17211B',
  muted: '#68746C',
  primary: '#183D30',
  primarySoft: '#DCEBE0',
  accent: '#C5E994',
  accentText: '#1C321E',
  border: '#DCE4DC',
  divider: '#EDF1EC',
  success: '#226C4A',
  successSoft: '#E3F2E8',
  warning: '#8B5522',
  warningSoft: '#FFF1D9',
  danger: '#9C4137',
  dangerSoft: '#FBE9E6',
  shadow: '#15251B',
};

export const darkPalette = {
  mode: 'dark' as const,
  background: '#111713',
  surface: '#1A211C',
  surfaceRaised: '#202A23',
  surfaceTint: '#28362C',
  text: '#EDF3EC',
  muted: '#A4B0A6',
  primary: '#D0F0A5',
  primarySoft: '#26392B',
  accent: '#C5E994',
  accentText: '#1C321E',
  border: '#344137',
  divider: '#29332C',
  success: '#9CD9AF',
  successSoft: '#24392B',
  warning: '#F1C27B',
  warningSoft: '#382E20',
  danger: '#FFB3A8',
  dangerSoft: '#3C2827',
  shadow: '#000000',
};

export type Palette = typeof lightPalette | typeof darkPalette;
export function usePalette(): Palette {
  return useColorScheme() === 'dark' ? darkPalette : lightPalette;
}
