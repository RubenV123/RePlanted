"""Generate the RePlated AIESEC Hackathon presentation (.pptx).

Layout is driven by the project's brand tokens from DESIGN.md:
  Background #F5F6F1, Primary #183D30, Accent #C5E994, Muted #68746C, Border #DCE4DC.
Five judge rubric slides are embedded as explicit decks; Q&A is its own slide.
"""

import os
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE

# ---------------------------------------------------------------------------
# Brand palette
# ---------------------------------------------------------------------------
BG           = RGBColor(0xF5, 0xF6, 0xF1)
SURFACE      = RGBColor(0xFF, 0xFF, 0xFF)
RAISED       = RGBColor(0xFF, 0xFF, 0xFF)
TEXT         = RGBColor(0x17, 0x21, 0x1B)
MUTED        = RGBColor(0x68, 0x74, 0x6C)
PRIMARY      = RGBColor(0x18, 0x3D, 0x30)
ACCENT       = RGBColor(0xC5, 0xE9, 0x94)
BORDER       = RGBColor(0xDC, 0xE4, 0xDC)
SUCCESS      = RGBColor(0x22, 0x6C, 0x4A)
WARNING      = RGBColor(0x8B, 0x55, 0x22)
DANGER       = RGBColor(0x9C, 0x41, 0x37)
WHITE        = RGBColor(0xFF, 0xFF, 0xFF)

SLIDE_W = Inches(13.333)   # 16:9 widescreen
SLIDE_H = Inches(7.5)

OUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "RePlated_Presentation.pptx"
)

prs = Presentation()
prs.slide_width = SLIDE_W
prs.slide_height = SLIDE_H
blank_layout = prs.slide_layouts[6]


# ---------------------------------------------------------------------------
# Slide helpers
# ---------------------------------------------------------------------------
def new_slide():
    return prs.slides.add_slide(blank_layout)


def add_rect(slide, left, top, w, h, fill, line=None, line_w=None):
    shp = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, left, top, w, h)
    shp.fill.solid(); shp.fill.fore_color.rgb = fill
    if line is None:
        shp.line.fill.background()
    else:
        shp.line.color.rgb = line
        shp.line.width = line_w if line_w else Pt(1)
    shp.shadow.inherit = False
    return shp


def add_rounded(slide, left, top, w, h, fill, line=None):
    shp = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, left, top, w, h)
    shp.fill.solid(); shp.fill.fore_color.rgb = fill
    if line is None:
        shp.line.fill.background()
    else:
        shp.line.color.rgb = line
        shp.line.width = Pt(1)
    shp.shadow.inherit = False
    return shp


def add_text(slide, left, top, w, h, runs, align=PP_ALIGN.LEFT, anchor=MSO_ANCHOR.TOP):
    """runs: list of (text, size, color, bold|None, italic|None) tuples."""
    tb = slide.shapes.add_textbox(left, top, w, h)
    tf = tb.text_frame
    tf.word_wrap = True
    tf.vertical_anchor = anchor
    for i, (txt, sz, col, b, ital) in enumerate(runs):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = align
        r = p.add_run()
        r.text = txt
        f = r.font
        f.size = Pt(sz); f.bold = b if b is not None else False
        f.italic = ital if ital is not None else False
        f.name = "Calibri"
        if col is not None:
            r.font.color.rgb = col
    return tb


def add_bullets(slide, left, top, w, h, items, sz=18, gap=12,
                col=TEXT, line_l=None):
    tb = slide.shapes.add_textbox(left, top, w, h)
    tf = tb.text_frame
    tf.word_wrap = True
    first = True
    for item in items:
        if not first:
            tf.add_paragraph()
        first = False
        p = tf.paragraphs[0]
        p.alignment = PP_ALIGN.LEFT
        # bullet glyph drawn as text
        bullet = "● " if False else ("▪   " if False else "  ● ")
        run = p.add_run()
        run.text = bullet + item
        f = run.font
        f.size = Pt(sz); f.color.rgb = col; f.bold = True; f.name = "Calibri"
        pPr = p.paragraph_format
        pPr.space_before = Pt(gap); pPr.space_after = Pt(gap - 4)
    return tb


def card(slide, l, t, w, h, fill=SURFACE, title=None, bullets=None,
         title_sz=20, body_sz=16, accent_y=None):
    """A rounded card. accent_y: y-offset where an accent bar appears under title."""
    c = add_rounded(slide, l, t, w, h, fill)
    c.shadow.inherit = False
    tb = slide.shapes.add_textbox(l + Inches(0.2), t + Inches(0.12),
                                  w - Inches(0.4), h - Inches(0.24))
    tf = tb.text_frame; tf.word_wrap = True
    parts = []
    if title:
        parts.append(("title", f"<b>{title}</b>", title_sz, PRIMARY))
        if accent_y is not None:
            bar = add_rect(slide, l + Inches(0.18), t + Inches(0.38) + accent_y,
                           Inches(0.08), Inches(0.07), ACCENT)
    if bullets:
        parts.append(("bullets", "", 16, MUTED))
    if not parts:
        return c
    ti = 0
    for kind, txt, sz, col in parts:
        p = tf.paragraphs[0] if ti == 0 else tf.add_paragraph()
        r = p.add_run(); r.text = txt
        r.font.size = Pt(sz); r.font.color.rgb = col; r.font.name = "Calibri"; r.font.bold = True
        pPr = p.paragraph_format; pPr.space_after = Pt(4)
        ti += 1
    return c


# ---------------------------------------------------------------------------
# Cover
# ---------------------------------------------------------------------------
s = new_slide()
add_rect(s, Inches(0), Inches(0), SLIDE_W, SLIDE_H, PRIMARY)
add_rect(s, Inches(0), Inches(2.9), SLIDE_W, Inches(0.06), ACCENT)
add_text(s, Inches(1.2), Inches(1.5), Inches(11), Inches(1.2),
         [("RePlated", 54, WHITE, True, None)])
add_text(s, Inches(1.2), Inches(3.4), Inches(11), Inches(0.7),
         [("Food Surplus · Chain-of-Custody App", 24, ACCENT, False, False)])
add_text(s, Inches(1.2), Inches(4.3), Inches(11), Inches(0.5),
         [("AIESEC Hackathon Presentation", 18, WHITE, False, True)])
add_text(s, Inches(1.2), Inches(4.8), Inches(11), Inches(0.5),
         [("A Python-generated deck aligned to the five judging rubrics", 14, MUTED, False, True)])

# ---------------------------------------------------------------------------
# Agenda
# ---------------------------------------------------------------------------
s = new_slide()
add_text(s, Inches(0.8), Inches(0.5), Inches(11), Inches(0.7),
         [("<b>Slide overview</b>", 28, PRIMARY, True, False)])
items = [
    ("01", "The problem we solve"),
    ("02", "Why this matters (who is affected)"),
    ("03", "Sustainable Development Goals & impact potential"),
    ("04", "Innovation & originality of the approach"),
    ("05", "Feasibility: stack, workspaces, prototype evidence"),
    ("06", "Pitch, demo pointers and Q&A prep"),
]
add_bullets(s, Inches(0.8), Inches(1.4), Inches(11.5), Inches(5.2),
            items, sz=22, gap=26, line_l=ACCENT)

# ---------------------------------------------------------------------------
# Section divider: Problem Understanding
# ---------------------------------------------------------------------------
s = new_slide()
add_rect(s, Inches(0), Inches(0), SLIDE_W, SLIDE_H, PRIMARY)
add_rect(s, Inches(0), Inches(2.7), SLIDE_W, Inches(0.06), ACCENT)
add_text(s, Inches(0.8), Inches(1.2), Inches(11), Inches(1.4),
         [("<b>1.</b> PROBLEM UNDERSTANDING", 30, WHITE, True, False)])
add_text(s, Inches(0.8), Inches(2.95), Inches(11), Inches(0.5),
         [("Clear, specific problem — who is affected and why it matters", 18, ACCENT, False, True)])
add_text(s, Inches(0.8), Inches(5.5), Inches(11), Inches(0.5),
         [("Problem〔Solution, affected actors, impact scope", 14, WHITE, False, True)])

# Two columns
card(s, Inches(0.7), Inches(3.8), Inches(5.8), Inches(3.2),
     title="THE PROBLEM",
     title_sz=22, body_sz=17, accent_y=Inches(0.48))
add_bullets(s, Inches(0.85), Inches(4.35), Inches(5.5), Inches(2.4),
    [
     "Large volumes of safe, edible food discarded at restaurants, events and kitchens because no organized handoff path exists.",
     "Vulnerable communities depend on NGOs receiving rescued food but the channel is fragmented — donors post locally, NGOs patchwork accept, no one records proof of delivery or inspection.",
     "Every missed handoff is a unit of food that goes uneaten AND a unit of evidence that goes unrecorded, making audits impossible.",
     "Stack breakdowns happen at the moments a batch changes hands — pickup, drop-off, inspection, review.",
    ], sz=15, gap=12, line_l=WARNING)
card(s, Inches(6.9), Inches(3.8), Inches(5.8), Inches(3.2),
     title="WHY IT MATTERS",
     title_sz=22, body_sz=17, accent_y=Inches(0.58))
add_bullets(s, Inches(7.05), Inches(4.35), Inches(5.5), Inches(2.4),
    [
     "Restaurant and event staff lose money on unsold surplus they cannot legally discard efficiently.",
     "NGO recipients cannot securely inspect incoming food without verified pickup-drop evidence.",
     "Delivery partners lack formal claim workflows, increasing double-booking and unclaimed batches.",
     "Without traceability, sustainability claims stay anecdotal and regulatory exposure grows.",
    ], sz=15, gap=12, line_l=ACCENT)

# ---------------------------------------------------------------------------
# Section divider: SDG Relevance & Impact Potential
# ---------------------------------------------------------------------------
s = new_slide()
add_rect(s, Inches(0), Inches(0), SLIDE_W, SLIDE_H, PRIMARY)
add_rect(s, Inches(0), Inches(2.7), SLIDE_W, Inches(0.06), ACCENT)
add_text(s, Inches(0.8), Inches(1.2), Inches(11), Inches(1.4),
         [("<b>2.</b> SDG RELEVANCE · IMPACT POTENTIAL", 28, WHITE, True, False)])
add_text(s, Inches(0.8), Inches(2.95), Inches(11), Inches(0.5),
         [("Explicit SDG links, meaningful potential impact", 18, ACCENT, False, True)])

# 6 SDG cards in a 3x2 grid
sdgs = [
    ("SDG 2", "Zero Hunger", "Recycle edible surplus into meals for vulnerable populations.", PRIMARY),
    ("SDG 11", "Responsible Cities & Communities", "Make surplus-food logistics visible and auditable at city level.", ACCENT),
    ("SDG 12", "Sustainable Consumption & Production", "Cut per-capita food waste by creating a traceable rescue supply chain.", SUCCESS),
    ("SDG 13", "Climate Action", "Prevent organic food waste methane emissions through rescue rather than landfill.", WARNING),
    ("SDG 8", "Decent Work", "Formalize handoff jobs for restaurant staff, riders and NGO volunteers.", DANGER),
    ("SDG 3", "Good Health & Wellbeing", "Standardized allergens and temperature records reduce food-safety incidents.", SUCCESS),
]
for i, (no, name, desc, col) in enumerate(sdgs):
    r, c = divmod(i, 3)
    x = Inches(0.6 + r * 4.1)
    y = Inches(3.7 + c * 1.75)
    add_rounded(s, x, y, Inches(3.9), Inches(1.55), SURFACE)
    add_rect(s, x, y, Inches(0.1), Inches(1.55), col)
    add_text(s, x + Inches(0.3), y + Inches(0.15), Inches(2.6), Inches(0.4),
             [(no, 16, col, True, False)], PP_ALIGN.LEFT)
    add_text(s, x + Inches(0.3), y + Inches(0.62), Inches(3.5), Inches(0.5),
             [(name, 17, TEXT, True, False)], PP_ALIGN.LEFT)
    add_text(s, x + Inches(0.3), y + Inches(1.1), Inches(3.4), Inches(0.4),
             [(desc, 13, MUTED, False, False)], PP_ALIGN.LEFT)

# ---------------------------------------------------------------------------
# Innovation & Originality
# ---------------------------------------------------------------------------
s = new_slide()
add_rect(s, Inches(0), Inches(0), SLIDE_W, SLIDE_H, PRIMARY)
add_rect(s, Inches(0), Inches(2.7), SLIDE_W, Inches(0.06), ACCENT)
add_text(s, Inches(0.8), Inches(1.2), Inches(11), Inches(1.4),
         [("<b>3.</b> INNOVATION & ORIGINALITY", 30, WHITE, True, False)])
add_text(s, Inches(0.8), Inches(2.95), Inches(11), Inches(0.5),
         [("Fresh idea or novel take — judge the idea, not the technology", 18, ACCENT, False, True)])

ideas = [
    ("Chain-of-custody batch code", "A single batch identifier follows a surplus item from donor offer → NGO capacity acceptance → rider pickup → inspection → review. Every role moves one step of the same ledger."),
    ("Role-gate flow", "NGO capacity acceptance precedes rider assignment. The product does not optimise pickups before the recipient is ready — it matches evidence to readiness."),
    ("Evidence-at-every-handoff", "Camera, measured temperature, allergen notes and pickup address are captured at each moment a batch changes hands. Safety statuses do not certify; they record."),
    ("Live rider map + inspection evidence", "During active deliveries, NGO sees a live foreground-tracked rider while the rider has the app open and granted location. Drop-off photos then ground inspection."),
    ("Graceful decline preserves records", "An NGO decline excludes that NGO from later offers for the same batch — the product learns organically instead of forcing bad matches forever."),
]
cols = [Inches(0.6), Inches(6.9)]
for ci, col in enumerate(cols):
    items_local = ideas[ci * 3:(ci + 1) * 3]
    add_rounded(s, col, Inches(3.7), Inches(5.85), Inches(3.3), SURFACE)
    add_rect(s, col, Inches(3.7), Inches(0.12), Inches(3.3), PRIMARY)
    bt = s.shapes.add_textbox(col + Inches(0.35), Inches(3.85), Inches(5.3), Inches(3.0))
    tf = bt.text_frame; tf.word_wrap = True
    for j, (t, d) in enumerate(items_local):
        p = tf.paragraphs[0] if j == 0 else tf.add_paragraph()
        r = p.add_run(); r.text = "▸ " + t; r.font.size = Pt(17); r.font.bold = True; r.font.color.rgb = PRIMARY; r.font.name = "Calibri"
        pPr = p.paragraph_format; pPr.space_after = Pt(4)
        p2 = tf.add_paragraph()
        r2 = p2.add_run(); r2.text = d; r2.font.size = Pt(14); r2.font.color.rgb = MUTED; r2.font.name = "Calibri"
        pPr2 = p2.paragraph_format; pPr2.space_after = Pt(10)

# ---------------------------------------------------------------------------
# Feasibility of Approach
# ---------------------------------------------------------------------------
s = new_slide()
add_rect(s, Inches(0), Inches(0), SLIDE_W, SLIDE_H, PRIMARY)
add_rect(s, Inches(0), Inches(2.7), SLIDE_W, Inches(0.06), ACCENT)
add_text(s, Inches(0.8), Inches(1.2), Inches(11), Inches(1.4),
         [("<b>4.</b> FEASIBILITY OF APPROACH", 30, WHITE, True, False)])
add_text(s, Inches(0.8), Inches(2.95), Inches(11), Inches(0.5),
         [("Realistic to prototype and implement — components and stack make sense", 18, ACCENT, False, True)])

# Stack row
rows = [
    ("App framework", "Expo / React Native — single codebase for Android and iOS with web layout variant", PRIMARY),
    ("Data layer", "Supabase Postgres — shared listings via Postgres, live sync via Realtime, private camera bucket via storage", ACCENT),
    ("Maps & location", "react-native-maps + foreground location only; system picker times; Android-only temp digits", WARNING),
    ("Auth / roles", "Admin-verified NGO and rider accounts; donor accounts on signup; roles read from profiles table", SUCCESS),
    ("Local demo mode", "Works without Supabase by default — demo records stay local and do not sync across devices", DANGER),
]
add_rounded(s, Inches(0.6), Inches(3.5), Inches(12.1), Inches(2.6), SURFACE)
add_rect(s, Inches(0.6), Inches(3.5), Inches(0.1), Inches(2.6), ACCENT)
it = s.shapes.add_textbox(Inches(0.85), Inches(3.6), Inches(11.5), Inches(2.3))
tf = it.text_frame; tf.word_wrap = True
for j, (k, v, col) in enumerate(rows):
    p = tf.paragraphs[0] if j == 0 else tf.add_paragraph()
    r = p.add_run(); r.text = k; r.font.size = Pt(16); r.font.bold = True; r.font.color.rgb = col; r.font.name = "Calibri"
    p2 = tf.add_paragraph()
    r2 = p2.add_run(); r2.text = "▸ " + v; r2.font.size = Pt(14); r2.font.color.rgb = MUTED; r2.font.name = "Calibri"
    pPr = p.paragraph_format; pPr.space_after = Pt(2)
    p2p = p2.paragraph_format; p2p.space_after = Pt(8)

# Capabilities column
caps = [
    ("Donor workspace", "Portions, food type, allergens, measured temperature, pickup deadline, address, safety confirmations, live camera evidence"),
    ("NGO recipient workspace", "Capacity assessment → accept / decline, post-delivery inspection, reason-coded review"),
    ("Rider workspace", "Claiming pickup, sharing active delivery location, documenting handoff photos"),
]
for i, (t, d) in enumerate(caps):
    y = Inches(6.3 + i * 0.42)
    add_text(s, Inches(0.8), y, Inches(2.0), Inches(0.4), [(t, 14, PRIMARY, True, False)], PP_ALIGN.LEFT)
    add_text(s, Inches(2.8), y, Inches(10), Inches(0.4), [(d, 13, MUTED, False, False)], PP_ALIGN.LEFT)

# ---------------------------------------------------------------------------
# Pitch & Demo Pointers
# ---------------------------------------------------------------------------
s = new_slide()
add_rect(s, Inches(0), Inches(0), SLIDE_W, SLIDE_H, PRIMARY)
add_rect(s, Inches(0), Inches(2.7), SLIDE_W, Inches(0.06), ACCENT)
add_text(s, Inches(0.8), Inches(1.2), Inches(11), Inches(1.4),
         [("<b>5.</b> PITCH, DEMO POINTERS & NEXT STEPS", 28, WHITE, True, False)])
add_text(s, Inches(0.8), Inches(2.95), Inches(11), Inches(0.5),
         [("Clear structure, demo pointers and concrete asks", 18, ACCENT, False, True)])

# Three pitch pillars
pillars = [
    ("VALUE PROPOSITION",
     "RePlated records the chain from surplus listing through rider handoff to NGO inspection, with one batch code and role-specific steps. Success = a clear owner, safe handling, evidence at handoff, recipient inspection and a traceable outcome."),
    ("DEMO POINTERS",
     "Start on the donor workspace: post a surplus batch. Move to the NGO workspace, pre-accept capacity, then rider claiming pickup and photo evidence. Then live-map rider during delivery. Finish with NGO inspection and review."),
    ("NEXT STEPS / ASK",
     "Validate OS operating procedures and FSSAI alignment before live distribution. Run Supabase migrations. Generate team accounts and switch roles via SQL. Local demo mode runs today and proves the core chain of custody."),
]
for i, (title, body) in enumerate(pillars):
    x = Inches(0.6 + i * 4.1)
    add_rounded(s, x, Inches(3.7), Inches(3.85), Inches(3.3), SURFACE)
    add_rect(s, x, Inches(3.7), Inches(0.1), Inches(3.3), ACCENT)
    bt = s.shapes.add_textbox(x + Inches(0.3), Inches(3.85), Inches(3.4), Inches(3.0))
    tf = bt.text_frame; tf.word_wrap = True
    p = tf.paragraphs[0]; r = p.add_run(); r.text = title; r.font.size = Pt(17); r.font.bold = True; r.font.color.rgb = PRIMARY; r.font.name = "Calibri"
    p.paragraph_format.space_after = Pt(4)
    p2 = tf.add_paragraph(); r2 = p2.add_run(); r2.text = body; r2.font.size = Pt(13); r2.font.color.rgb = MUTED; r2.font.name = "Calibri"
    p2.paragraph_format.space_after = Pt(10)

# ---------------------------------------------------------------------------
# Q&A prep slide with likely questions and prepared answers
# ---------------------------------------------------------------------------
s = new_slide()
add_rect(s, Inches(0), Inches(0), SLIDE_W, SLIDE_H, PRIMARY)
add_rect(s, Inches(0), Inches(2.7), SLIDE_W, Inches(0.06), ACCENT)
add_text(s, Inches(0.8), Inches(1.2), Inches(11), Inches(1.4),
         [("<b>6.</b> JUDGE QUESTIONS & PREPARED ANSWERS", 28, WHITE, True, False)])
add_text(s, Inches(0.8), Inches(2.95), Inches(11), Inches(0.5),
         [("Anticipate judge queries and match each to the rubric it targets", 18, ACCENT, False, True)])

qa = [
    ("Q1 — What specific problem does RePlated solve?",
     "A: Large quantities of safe edible food are wasted at kitchens and events because there is no organised chain of custody from donor to NGO. For vulnerable communities, food insecurity is persistent and imports still outpace domestic availability; this app turns surplus into rescued meals with documented ownership."),
    ("Q2 — Who is affected and why does it matter?",
     "A: Restaurant and event staff lose money on unsold surplus they cannot legally dispose of cleanly. NGO recipients cannot inspect incoming food without verified pickup evidence, so unsafe or mislabeled batches go unchallenged. Riders lack formal claim flows, increasing unclaimed batches. All three actors fail to produce audit-grade evidence."),
    ("Q3 — Which SDGs does it explicitly target and how?",
     "A: Directly SDG 2 (Zero Hunger), SDG 12 (Sustainable Consumption & Production), SDG 13 (Climate Action — reducing methane from food waste), SDG 8 (Decent Work), SDG 11 (Responsible Cities). Indirectly SDG 3 via allergen and temperature evidence."),
    ("Q4 — How original is the idea versus existing food-rescue apps?",
     "A: Existing tools list surplus food informally. RePlated adds a single batch code that follows a batch through every role transition, with capacity acceptance gating rider assignment, and photo/temperature evidence at each handoff — making the chain auditable."),
    ("Q5 — Is the stack feasible to prototype today?",
     "A: Yes. Expo / React Native is a standard mobile stack, Supabase is already wired with RLS and a private camera bucket, and local demo mode runs out-of-the-box without credentials. The local-only nature also keeps the prototype production-safe until Supabase is provisioned."),
    ("Q6 — Can you prototype the core flow right now?",
     "A: Yes. Donor workspace → NGO capacity accept → rider pickup claim with photo evidence → live rider map → NGO inspection → review. The demo runs with `npm start`; Supabase connect switches to shared LiveRows and cross-device sync."),
    ("Q7 — What is the biggest limitation to note honestly?",
     "A: Foreground location depends on the rider keeping the app open and granted permission, and camera evidence does not certify food safety. We recommend validating real operating procedures and FSSAI alignment before live distribution — which is exactly our stated next step."),
]
bt = s.shapes.add_textbox(Inches(0.7), Inches(3.6), Inches(12.0), Inches(3.6))
tf = bt.text_frame; tf.word_wrap = True
for j, (q, a) in enumerate(qa):
    if j == 0:
        p = tf.paragraphs[0]
    else:
        p = tf.add_paragraph()
    r = p.add_run(); r.text = q; r.font.size = Pt(14); r.font.bold = True; r.font.color.rgb = ACCENT; r.font.name = "Calibri"
    p2 = tf.add_paragraph()
    r2 = p2.add_run(); r2.text = "Answer: " + a; r2.font.size = Pt(13); r2.font.color.rgb = TEXT; r2.font.name = "Calibri"
    p.paragraph_format.space_after = Pt(8)
    p2.paragraph_format.space_after = Pt(12)

# ---------------------------------------------------------------------------
# Thank you / closing
# ---------------------------------------------------------------------------
s = new_slide()
add_rect(s, Inches(0), Inches(0), SLIDE_W, SLIDE_H, PRIMARY)
add_text(s, Inches(1.5), Inches(2.6), Inches(10), Inches(1.0),
         [("Thank you — questions welcome", 40, WHITE, True, False)])
add_rect(s, Inches(5.3), Inches(3.7), Inches(2.7), Inches(0.05), ACCENT)
add_text(s, Inches(1.5), Inches(4.2), Inches(10), Inches(0.8),
         [("RePlated", 22, WHITE, False, False)])
add_text(s, Inches(1.5), Inches(5.0), Inches(10), Inches(0.6),
         [("surplus.rescue", 16, ACCENT, False, True)])
add_text(s, Inches(1.5), Inches(5.7), Inches(10), Inches(0.6),
         [("Strengthened by the rubric-aligned explanation above", 13, WHITE, False, True)])

prs.save(OUT)
print("Saved:", OUT)
print("Slides:", len(prs.slides))
