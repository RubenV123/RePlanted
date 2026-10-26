export type RiskLevel = 'high' | 'medium' | 'low';
export type TemperatureState = 'hot-held' | 'cold-held' | 'danger-zone';
export type FoodCategoryRule = { id: string; label: string; risk: RiskLevel; keywords: string[] };
export type ChecklistStep = 'donor' | 'rider' | 'ngo';
export type SafetyConfig = {
  HOT_MIN_C: number;
  COLD_MAX_C: number;
  WINDOW_HIGH_RISK_H: number;
  WINDOW_MEDIUM_RISK_H: number;
  WINDOW_LOW_RISK_H: number;
  NGO_ARRIVAL_BUFFER_MIN: number;
  LOCATION_MISMATCH_M: number;
  COMPLAINT_WINDOW_H: number;
  ESTIMATE_PROMPT: string;
  PACK_DEADLINE: string;
  PICKUP_TIME: string;
  PACK_AUTO_CANCEL_AT: string;
  QUANTITY_TOLERANCE_PCT: number;
  BADGE_THRESHOLDS: { Bronze: number; Silver: number; Gold: number };
  CATEGORIES: FoodCategoryRule[];
  CHECKLISTS: Record<ChecklistStep, string[]>;
};

export const DEFAULT_SAFETY_CONFIG: SafetyConfig = {
  HOT_MIN_C: 60,
  COLD_MAX_C: 5,
  WINDOW_HIGH_RISK_H: 2,
  WINDOW_MEDIUM_RISK_H: 3,
  WINDOW_LOW_RISK_H: 4,
  NGO_ARRIVAL_BUFFER_MIN: 15,
  LOCATION_MISMATCH_M: 200,
  COMPLAINT_WINDOW_H: 48,
  ESTIMATE_PROMPT: '16:00',
  PACK_DEADLINE: '18:30',
  PICKUP_TIME: '19:00',
  PACK_AUTO_CANCEL_AT: '19:30',
  QUANTITY_TOLERANCE_PCT: 20,
  BADGE_THRESHOLDS: { Bronze: 100, Silver: 500, Gold: 1000 },
  CATEGORIES: [
    { id: 'rice', label: 'Rice dishes / biryani', risk: 'high', keywords: ['rice', 'biryani', 'pulao', 'khichdi'] },
    { id: 'curry', label: 'Curries / gravies / dal', risk: 'high', keywords: ['curry', 'gravy', 'dal', 'sambar', 'rasam', 'korma'] },
    { id: 'dairy', label: 'Dairy / paneer / egg', risk: 'high', keywords: ['dairy', 'milk', 'paneer', 'cheese', 'cream', 'egg', 'omelette'] },
    { id: 'meat', label: 'Meat / fish dishes', risk: 'high', keywords: ['meat', 'chicken', 'mutton', 'fish', 'prawn', 'seafood'] },
    { id: 'bread', label: 'Bread / rotis', risk: 'low', keywords: ['bread', 'roti', 'chapati', 'naan', 'paratha'] },
    { id: 'snacks', label: 'Dry snacks', risk: 'low', keywords: ['dry snack', 'namkeen', 'mixture', 'chips', 'cracker'] },
    { id: 'bakery', label: 'Bakery', risk: 'low', keywords: ['biscuit', 'cookie', 'cake', 'muffin', 'pastry', 'bakery'] },
    { id: 'prepared', label: 'Other prepared foods', risk: 'medium', keywords: ['noodle', 'pasta', 'salad', 'fruit', 'vegetable'] },
  ],
  CHECKLISTS: {
    donor: [
      'Food was never served to customers or guests', 'No leftovers from plates',
      'Covered in clean food-grade containers', 'Every box labelled with the batch code',
      'Every box sealed with the sticker', 'Allergens listed',
    ],
    rider: ['Box count matches', 'Seals intact', 'Packaging clean and undamaged', 'Delivery bag clean'],
    ngo: ['Seals intact', 'Looks fresh', 'Smells fine', 'Packaging intact', 'Quantity matches'],
  },
};

export function normalizeSafetyConfig(input: unknown): SafetyConfig {
  if (!input || typeof input !== 'object') return DEFAULT_SAFETY_CONFIG;
  const value = input as Partial<SafetyConfig>;
  return {
    ...DEFAULT_SAFETY_CONFIG,
    ...value,
    BADGE_THRESHOLDS: { ...DEFAULT_SAFETY_CONFIG.BADGE_THRESHOLDS, ...value.BADGE_THRESHOLDS },
    CATEGORIES: Array.isArray(value.CATEGORIES) ? value.CATEGORIES : DEFAULT_SAFETY_CONFIG.CATEGORIES,
    CHECKLISTS: { ...DEFAULT_SAFETY_CONFIG.CHECKLISTS, ...value.CHECKLISTS },
  };
}

export function classifyFoodName(name: string, config: SafetyConfig = DEFAULT_SAFETY_CONFIG) {
  const normalized = name.trim().toLocaleLowerCase();
  // High-risk keyword matches win if a dish name contains multiple category terms.
  for (const category of config.CATEGORIES) {
    if (category.risk === 'high' && category.keywords.some(word => normalized.includes(word.toLocaleLowerCase()))) return category;
  }
  for (const category of config.CATEGORIES) {
    if (category.risk !== 'high' && category.keywords.some(word => normalized.includes(word.toLocaleLowerCase()))) return category;
  }
  return { id: 'prepared', label: 'Other prepared foods', risk: 'high' as const, keywords: [] };
}

export function classifyTemperature(celsius: number, config: SafetyConfig = DEFAULT_SAFETY_CONFIG): TemperatureState {
  if (!Number.isFinite(celsius)) return 'danger-zone';
  if (celsius >= config.HOT_MIN_C) return 'hot-held';
  if (celsius <= config.COLD_MAX_C) return 'cold-held';
  return 'danger-zone';
}

export function hoursForRisk(risk: RiskLevel, config: SafetyConfig = DEFAULT_SAFETY_CONFIG) {
  return risk === 'high' ? config.WINDOW_HIGH_RISK_H : risk === 'low' ? config.WINDOW_LOW_RISK_H : config.WINDOW_MEDIUM_RISK_H;
}

export function isHighRiskTemperatureBlocked(risk: RiskLevel, temperature: number, config: SafetyConfig = DEFAULT_SAFETY_CONFIG) {
  return risk === 'high' && classifyTemperature(temperature, config) === 'danger-zone';
}

export function safeUntilFromPackedAt(packedAt: string | Date, risk: RiskLevel, config: SafetyConfig = DEFAULT_SAFETY_CONFIG) {
  return new Date(new Date(packedAt).getTime() + hoursForRisk(risk, config) * 60 * 60 * 1000);
}

export type CountdownTone = 'safe' | 'soon' | 'urgent' | 'expired';
export function countdownTone(safeUntil: string | Date, now = Date.now()): CountdownTone {
  const remaining = new Date(safeUntil).getTime() - now;
  if (remaining <= 0) return 'expired';
  if (remaining <= 15 * 60_000) return 'urgent';
  if (remaining <= 60 * 60_000) return 'soon';
  return 'safe';
}

export function expectedArrivalIsTooLate(arrivalAt: string | Date, safeUntil: string | Date, config: SafetyConfig = DEFAULT_SAFETY_CONFIG) {
  return new Date(arrivalAt).getTime() >= new Date(safeUntil).getTime() - config.NGO_ARRIVAL_BUFFER_MIN * 60_000;
}

export function isFutureTimeToday(time: string, now = new Date()) {
  if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(time)) return true;
  const [hours, minutes] = time.split(':').map(Number);
  return hours * 60 + minutes > now.getHours() * 60 + now.getMinutes();
}

export function badgeForPoints(points: number, config: SafetyConfig = DEFAULT_SAFETY_CONFIG) {
  if (points >= config.BADGE_THRESHOLDS.Gold) return 'Gold';
  if (points >= config.BADGE_THRESHOLDS.Silver) return 'Silver';
  if (points >= config.BADGE_THRESHOLDS.Bronze) return 'Bronze';
  return undefined;
}
