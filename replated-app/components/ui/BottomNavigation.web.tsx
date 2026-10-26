import React from 'react';
import { Pressable, StyleSheet, Text, View, useWindowDimensions } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import type { LucideIcon } from 'lucide-react-native';
import { usePalette } from './palette';

type TabItem = { key: string; label: string; icon: LucideIcon };
export function BottomNavigation({ items, active, onChange }: { items: TabItem[]; active: string; onChange: (key: string) => void }) {
  const p = usePalette();
  const { width } = useWindowDimensions();
  const desktop = width >= 980;
  if (desktop) return <View style={[s.sidebar,{backgroundColor:p.background,borderRightColor:p.border}]}>
    <Text style={[s.eyebrow,{color:p.muted}]}>WORKSPACE</Text>
    <View style={s.desktopItems}>{items.map(({key,label,icon:Icon})=>{
      const selected=active===key;
      return <Pressable key={key} accessibilityRole="tab" accessibilityState={{selected}} onPress={()=>onChange(key)} style={[s.desktopTab,selected&&{backgroundColor:p.surfaceTint}]}>
        <Icon size={19} color={selected?p.primary:p.muted} strokeWidth={selected?2.5:2}/>
        <Text style={[s.desktopLabel,{color:selected?p.primary:p.muted},selected&&s.desktopActive]}>{label}</Text>
      </Pressable>;
    })}</View>
    <View style={[s.safetyHint,{backgroundColor:p.surfaceTint}]}><Text style={[s.safetyTitle,{color:p.text}]}>Every handoff matters</Text><Text style={[s.safetyCopy,{color:p.muted}]}>Keep batches traceable and inspect food on arrival.</Text></View>
  </View>;
  return <SafeAreaView edges={['bottom']} style={[s.mobileSafe,{backgroundColor:p.surface,borderTopColor:p.border}]}>
    <View style={s.mobileBar}>{items.map(({ key, label, icon: Icon }) => {
      const selected = active === key;
      return <Pressable key={key} accessibilityRole="tab" accessibilityState={{ selected }} onPress={() => onChange(key)} style={s.mobileTab}>
        <View style={[s.iconWrap, selected && { backgroundColor: p.primarySoft }]}><Icon size={20} color={selected ? p.primary : p.muted} strokeWidth={selected ? 2.5 : 2} /></View>
        <Text numberOfLines={1} style={[s.mobileLabel, { color: selected ? p.primary : p.muted }, selected && s.mobileActive]}>{label}</Text>
      </Pressable>;
    })}</View>
  </SafeAreaView>;
}
const s=StyleSheet.create({sidebar:{width:220,flexShrink:0,borderRightWidth:StyleSheet.hairlineWidth,paddingTop:24,paddingRight:18,paddingBottom:22},eyebrow:{fontSize:10,fontWeight:'800',letterSpacing:1,paddingHorizontal:12,marginBottom:14},desktopItems:{gap:5},desktopTab:{minHeight:46,borderRadius:13,paddingHorizontal:12,flexDirection:'row',alignItems:'center',gap:12},desktopLabel:{fontSize:13,fontWeight:'600'},desktopActive:{fontWeight:'800'},safetyHint:{marginTop:'auto',padding:14,borderRadius:15},safetyTitle:{fontSize:12,fontWeight:'700'},safetyCopy:{fontSize:11,lineHeight:16,marginTop:5},mobileSafe:{borderTopWidth:StyleSheet.hairlineWidth},mobileBar:{minHeight:66,flexDirection:'row',alignItems:'center',justifyContent:'space-around',paddingHorizontal:7,paddingTop:5},mobileTab:{minWidth:66,minHeight:56,alignItems:'center',justifyContent:'center',gap:3,paddingHorizontal:8},iconWrap:{width:34,height:28,borderRadius:11,alignItems:'center',justifyContent:'center'},mobileLabel:{fontSize:10,fontWeight:'600'},mobileActive:{fontWeight:'800'}});
