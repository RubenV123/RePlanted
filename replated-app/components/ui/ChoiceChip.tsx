import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { usePalette } from './palette';

export function ChoiceChip({ label, selected, onPress }: { label: string; selected: boolean; onPress: () => void }) {
  const p = usePalette();
  return <Pressable accessibilityRole="radio" accessibilityState={{ selected }} onPress={onPress} style={[s.chip, { backgroundColor: selected ? p.primary : p.surfaceTint, borderColor: selected ? p.primary : p.border }]}>
    <Text style={[s.label, { color: selected ? (p.mode === 'dark' ? '#17211B' : '#FFFFFF') : p.text }]}>{label}</Text>
  </Pressable>;
}
const s=StyleSheet.create({chip:{minHeight:42,borderRadius:13,borderWidth:1,paddingHorizontal:13,alignItems:'center',justifyContent:'center'},label:{fontSize:12,fontWeight:'700'}});
