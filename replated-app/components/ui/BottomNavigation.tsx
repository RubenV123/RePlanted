import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import type { LucideIcon } from 'lucide-react-native';
import { usePalette } from './palette';

type TabItem = { key: string; label: string; icon: LucideIcon };
export function BottomNavigation({ items, active, onChange }: { items: TabItem[]; active: string; onChange: (key: string) => void }) {
  const p = usePalette();
  return <SafeAreaView edges={['bottom']} style={[s.safe, { backgroundColor: p.surface, borderTopColor: p.border }]}>
    <View style={s.bar}>{items.map(({ key, label, icon: Icon }) => {
      const selected = active === key;
      return <Pressable key={key} accessibilityRole="tab" accessibilityState={{ selected }} onPress={() => onChange(key)} style={s.tab}>
        <View style={[s.iconWrap, selected && { backgroundColor: p.primarySoft }]}><Icon size={20} color={selected ? p.primary : p.muted} strokeWidth={selected ? 2.5 : 2} /></View>
        <Text numberOfLines={1} style={[s.label, { color: selected ? p.primary : p.muted }, selected && s.activeLabel]}>{label}</Text>
      </Pressable>;
    })}</View>
  </SafeAreaView>;
}
const s = StyleSheet.create({ safe: { borderTopWidth: StyleSheet.hairlineWidth }, bar: { minHeight: 66, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-around', paddingHorizontal: 7, paddingTop: 5 }, tab: { minWidth: 66, minHeight: 56, alignItems: 'center', justifyContent: 'center', gap: 3, paddingHorizontal: 8 }, iconWrap: { width: 34, height: 28, borderRadius: 11, alignItems: 'center', justifyContent: 'center' }, label: { fontSize: 10, fontWeight: '600' }, activeLabel: { fontWeight: '800' } });
