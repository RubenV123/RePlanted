import React from 'react';
import { Pressable, StyleSheet, Text, TextInput, View, type PressableProps } from 'react-native';
import Animated, { useAnimatedStyle, useSharedValue, withSpring } from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';
import type { LucideIcon } from 'lucide-react-native';
import { usePalette } from './palette';

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);
type Props = Omit<PressableProps, 'onPress' | 'children'> & {
  label: string;
  onPress: () => void;
  subtle?: boolean;
  outline?: boolean;
  disabled?: boolean;
  icon?: LucideIcon;
  trailingIcon?: LucideIcon;
  compact?: boolean;
  flex?: boolean;
};

export function Button({ label, onPress, subtle, outline, disabled, icon: Icon, trailingIcon: EndIcon, compact, flex, ...props }: Props) {
  const p = usePalette();
  const scale = useSharedValue(1);
  const pressStyle = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] }));
  const variant = subtle ? styles.tonal : outline ? styles.outlined : styles.filled;
  const foreground = subtle ? p.primary : outline ? p.text : (p.mode === 'dark' ? '#152018' : '#FFFFFF');
  return (
    <Animated.View style={[pressStyle, flex && { flex: 1 }]}>
      <AnimatedPressable
        {...props}
        accessibilityRole="button"
        accessibilityState={{ disabled: !!disabled }}
        disabled={disabled}
        onPressIn={() => { if (!disabled) { scale.value = withSpring(0.965, { damping: 18, stiffness: 280 }); void Haptics.selectionAsync(); } }}
        onPressOut={() => { scale.value = withSpring(1, { damping: 16, stiffness: 240 }); }}
        onPress={onPress}
        style={[styles.button, variant, { backgroundColor: subtle ? p.surfaceTint : outline ? 'transparent' : p.primary, borderColor: p.border }, disabled && styles.disabled, compact && styles.compact, props.style]}
      >
        {Icon && <Icon size={18} color={foreground} strokeWidth={2.25} />}
        <Text style={[styles.label, { color: foreground }]}>{label}</Text>
        {EndIcon && <EndIcon size={17} color={foreground} strokeWidth={2.2} />}
      </AnimatedPressable>
    </Animated.View>
  );
}

export function FormField({ label, value, onChangeText, keyboardType = 'default', multiline, placeholder, autoCapitalize, secureTextEntry }: {
  label: string; value: string; onChangeText: (value: string) => void; keyboardType?: any; multiline?: boolean;
  placeholder?: string; autoCapitalize?: any; secureTextEntry?: boolean;
}) {
  const p = usePalette();
  return <View style={styles.field}>
    <Text style={[styles.fieldLabel, { color: p.muted }]}>{label}</Text>
    <TextInput
      accessibilityLabel={label.replace(/\s*\*$/, '')}
      value={value}
      onChangeText={onChangeText}
      keyboardType={keyboardType}
      multiline={multiline}
      placeholder={placeholder}
      placeholderTextColor={p.muted}
      autoCapitalize={autoCapitalize}
      secureTextEntry={secureTextEntry}
      selectionColor={p.primary}
      style={[styles.input, { backgroundColor: p.surfaceRaised, color: p.text, borderColor: p.border }, multiline && styles.multiline]}
    />
  </View>;
}

export function TimeField({ label, value, onPress }: { label: string; value: string; onPress: () => void }) {
  const p = usePalette();
  return <View style={styles.field}>
    <Text style={[styles.fieldLabel, { color: p.muted }]}>{label}</Text>
    <Pressable accessibilityRole="button" onPress={onPress} style={[styles.input, styles.timeInput, { backgroundColor: p.surfaceRaised, borderColor: p.border }]}>
      <Text style={[styles.timeText, { color: value ? p.text : p.muted }]}>{value || 'Choose a time'}</Text>
      <Text style={[styles.timeHint, { color: p.muted }]}>24-hour</Text>
    </Pressable>
  </View>;
}

export function SurfaceCard({ children, style }: { children: React.ReactNode; style?: any }) {
  const p = usePalette();
  return <View style={[styles.card, { backgroundColor: p.surface, borderColor: p.border }, style]}>{children}</View>;
}

export function IconBadge({ icon: Icon, tint, size = 44 }: { icon: LucideIcon; tint?: string; size?: number }) {
  const p = usePalette();
  return <View style={[styles.iconBadge, { width: size, height: size, borderRadius: size * 0.34, backgroundColor: tint || p.surfaceTint }]}>
    <Icon size={size * 0.45} color={p.primary} strokeWidth={2.1} />
  </View>;
}

export function SectionTitle({ title, detail, action }: { title: string; detail?: string; action?: React.ReactNode }) {
  const p = usePalette();
  return <View style={styles.sectionHeading}>
    <View style={{ flex: 1 }}><Text style={[styles.sectionTitle, { color: p.text }]}>{title}</Text>{detail && <Text style={[styles.sectionDetail, { color: p.muted }]}>{detail}</Text>}</View>
    {action}
  </View>;
}

const styles = StyleSheet.create({
  button: { minHeight: 50, paddingHorizontal: 16, borderRadius: 15, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 9 },
  filled: { backgroundColor: '#183D30' },
  tonal: { backgroundColor: '#EAF0E9' },
  outlined: { backgroundColor: 'transparent', borderWidth: 1 },
  disabled: { opacity: 0.42 },
  compact: { minHeight: 44, paddingHorizontal: 13, borderRadius: 13 },
  label: { fontSize: 14, fontWeight: '700', letterSpacing: -0.1 },
  field: { marginTop: 14 },
  fieldLabel: { fontSize: 12, fontWeight: '700', marginBottom: 7, letterSpacing: 0.1 },
  input: { minHeight: 50, borderWidth: 1, borderRadius: 14, paddingHorizontal: 14, paddingVertical: 12, fontSize: 15 },
  multiline: { minHeight: 96, textAlignVertical: 'top' },
  timeInput: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  timeText: { fontSize: 15, fontWeight: '600' },
  timeHint: { fontSize: 11, fontWeight: '600' },
  card: { borderRadius: 22, borderWidth: 1, padding: 17, marginTop: 12 },
  iconBadge: { alignItems: 'center', justifyContent: 'center' },
  sectionHeading: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12, marginTop: 27, marginBottom: 8 },
  sectionTitle: { fontSize: 19, lineHeight: 24, fontWeight: '700', letterSpacing: -0.4 },
  sectionDetail: { fontSize: 13, lineHeight: 18, marginTop: 3 },
});

