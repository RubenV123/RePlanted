import React from 'react';
import { Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import { ArrowRight, Leaf, LogOut, type LucideIcon } from 'lucide-react-native';
import { usePalette } from './palette';

export function BrandMark({ small = false }: { small?: boolean }) {
  const p = usePalette();
  return <View style={[s.mark, small && s.markSmall, { backgroundColor: p.mode === 'dark' ? '#183D30' : p.primary }]}><Leaf size={small ? 17 : 21} color={p.accent} strokeWidth={2.4} /></View>;
}

export function AppHeader({ name, role, onSignOut }: { name: string; role: string; onSignOut: () => void }) {
  const p = usePalette();
  return <View style={[s.header, { backgroundColor: p.background, borderBottomColor: p.divider }]}>
    <View style={s.identity}><BrandMark small/><View><Text style={[s.brand, { color: p.text }]}>replated</Text><Text style={[s.caption, { color: p.muted }]}>{name} · {role}</Text></View></View>
    <Pressable accessibilityRole="button" accessibilityLabel="Sign out or switch role" onPress={onSignOut} style={[s.action, { backgroundColor: p.surfaceTint }]}><LogOut size={18} color={p.primary} strokeWidth={2.2}/></Pressable>
  </View>;
}

export function StatusPill({ label, tone = 'neutral' }: { label: string; tone?: 'neutral'|'success'|'warning'|'danger'|'accent' }) {
  const p = usePalette();
  const colors = tone === 'success' ? [p.successSoft,p.success] : tone === 'warning' ? [p.warningSoft,p.warning] : tone === 'danger' ? [p.dangerSoft,p.danger] : tone === 'accent' ? [p.primarySoft,p.primary] : [p.surfaceTint,p.muted];
  return <View style={[s.pill, { backgroundColor: colors[0] }]}><View style={[s.dot, { backgroundColor: colors[1] }]} /><Text style={[s.pillText, { color: colors[1] }]}>{label}</Text></View>;
}

export function FeatureRow({ icon: Icon, title, detail, onPress }: { icon: LucideIcon; title: string; detail: string; onPress?: () => void }) {
  const p = usePalette();
  const content = <><View style={[s.featureIcon, { backgroundColor: p.surfaceTint }]}><Icon size={20} color={p.primary} strokeWidth={2}/></View><View style={{ flex: 1 }}><Text style={[s.featureTitle,{color:p.text}]}>{title}</Text><Text style={[s.featureDetail,{color:p.muted}]}>{detail}</Text></View><ArrowRight size={17} color={p.muted}/></>;
  return onPress ? <Pressable onPress={onPress} style={[s.feature,{borderBottomColor:p.divider}]}>{content}</Pressable> : <View style={[s.feature,{borderBottomColor:p.divider}]}>{content}</View>;
}
const s=StyleSheet.create({mark:{width:54,height:54,borderRadius:19,alignItems:'center',justifyContent:'center'},markSmall:{width:42,height:42,borderRadius:15},header:{paddingHorizontal:20,paddingVertical:12,borderBottomWidth:StyleSheet.hairlineWidth,flexDirection:'row',alignItems:'center',justifyContent:'space-between',...(Platform.OS==='web'?{width:'100%',maxWidth:1420,alignSelf:'center'}:{})},identity:{flexDirection:'row',alignItems:'center',gap:11},brand:{fontSize:18,fontWeight:'800',letterSpacing:-.45},caption:{fontSize:11,fontWeight:'600',marginTop:2},action:{width:44,height:44,borderRadius:15,alignItems:'center',justifyContent:'center'},pill:{paddingHorizontal:10,paddingVertical:6,borderRadius:999,alignSelf:'flex-start',flexDirection:'row',alignItems:'center',gap:6},dot:{width:6,height:6,borderRadius:3},pillText:{fontSize:11,fontWeight:'700'},feature:{minHeight:70,borderBottomWidth:StyleSheet.hairlineWidth,flexDirection:'row',alignItems:'center',gap:12,paddingVertical:12},featureIcon:{width:42,height:42,borderRadius:14,alignItems:'center',justifyContent:'center'},featureTitle:{fontSize:14,fontWeight:'700'},featureDetail:{fontSize:12,lineHeight:17,marginTop:3}});
