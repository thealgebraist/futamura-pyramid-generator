from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak

OUT = "futamura_problem_solving_template.pdf"
styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="TitleCenter", parent=styles["Title"], alignment=TA_CENTER, textColor=colors.HexColor("#18324B"), spaceAfter=18))
styles.add(ParagraphStyle(name="Lead", parent=styles["BodyText"], fontSize=11, leading=15, textColor=colors.HexColor("#334155"), spaceAfter=12))
styles.add(ParagraphStyle(name="Small", parent=styles["BodyText"], fontSize=9, leading=12))
styles.add(ParagraphStyle(name="CodeBlock", parent=styles["Code"], fontName="Courier", fontSize=8, leading=10, backColor=colors.HexColor("#F1F5F9"), borderPadding=8, spaceBefore=5, spaceAfter=8))

def footer(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(colors.HexColor("#64748B"))
    canvas.drawString(.7 * inch, .45 * inch, "Futamura Projection Problem-Solving Template")
    canvas.drawRightString(7.8 * inch, .45 * inch, str(doc.page))
    canvas.restoreState()

doc = SimpleDocTemplate(OUT, pagesize=letter, rightMargin=.7*inch, leftMargin=.7*inch, topMargin=.65*inch, bottomMargin=.7*inch)
story = []
story.append(Paragraph("A Small, Typed, Staged Way to Solve Problems", styles["TitleCenter"]))
story.append(Paragraph("A reusable prompt template derived from the pyramid database session. It combines a domain-specific language, an explicit semantic specification, type-indexed validation, and Futamura-style partial evaluation.", styles["Lead"]))
story.append(Paragraph("Core idea", styles["Heading2"]))
story.append(Paragraph("Separate what is known now from what must remain dynamic. Parse and validate the specification while generating the artifact; specialize away everything fixed; leave only residual runtime behavior in the final program.", styles["BodyText"]))
story.append(Paragraph("Surface input -> typed semantic specification -> reference interpreter + specializer -> residual artifact", styles["CodeBlock"]))
story.append(Paragraph("General prompt template", styles["Heading2"]))
template = """You are designing a small, auditable implementation for this problem:\n\n[PROBLEM]\n\n1. Define the smallest surface DSL users need. State its grammar and valid/invalid examples.\n2. Define one declarative schema. Each named value has a semantic kind, representation, and invariant.\n3. Define the semantic domain mathematically or with a compact algebraic data type.\n4. Separate stages: parse : Surface -> Parsed; validate : Parsed -> Validated or Error; interpret : Validated x Input -> Result; specialize : Validated -> ResidualProgram.\n5. Use type indices, phantom types, GADTs, dependent types, or checked constructors only where they prevent a real invalid state. Erase them after validation.\n6. Apply the first Futamura projection: partially evaluate the interpreter with respect to the validated static specification. List what disappears from the output.\n7. Keep HTTP, databases, and files behind adapters. Keep the semantic core deterministic and dependency-light.\n8. Generate the smallest readable target program: only dynamic data, residual control flow, and runtime effects.\n9. Verify by differential testing: reference interpreter result == residual program result. Test every type rule with invalid input.\n10. Report uncertainty, unsupported grammar, missing data, and empirical versus formal claims.\n\nDeliver the grammar, semantic specification, staging boundaries, interpreter, specializer, generated artifact, and verification commands."""
story.append(Paragraph(template.replace("\n", "<br/>"), styles["CodeBlock"]))
story.append(Paragraph("Review checklist", styles["Heading2"]))
rows = [["Question", "Pass condition"], ["Static?", "Schema, validated query, limits, predicates, and output shape are fixed before specialization."], ["Dynamic?", "Only genuinely unknown records, values, or effects remain."], ["Error boundary?", "Invalid syntax and types are rejected before specialization."], ["Residual?", "The output has no unnecessary parser, AST, or dynamic dispatch."], ["Evidence?", "Claims are supported by types, executable checks, or explicit finite evidence."], ["External?", "Network and acquisition logic are visible adapters."]]
table = Table([[Paragraph(c, styles["Small"]) for c in row] for row in rows], colWidths=[1.35*inch, 5.2*inch], repeatRows=1)
table.setStyle(TableStyle([("BACKGROUND", (0,0), (-1,0), colors.HexColor("#18324B")), ("TEXTCOLOR", (0,0), (-1,0), colors.white), ("GRID", (0,0), (-1,-1), .35, colors.HexColor("#CBD5E1")), ("VALIGN", (0,0), (-1,-1), "TOP"), ("ROWBACKGROUNDS", (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]), ("LEFTPADDING", (0,0), (-1,-1), 7), ("RIGHTPADDING", (0,0), (-1,-1), 7), ("TOPPADDING", (0,0), (-1,-1), 6), ("BOTTOMPADDING", (0,0), (-1,-1), 6)]))
story.extend([table, Spacer(1, 12), Paragraph("Session-derived rules", styles["Heading2"])])
rules = ["Use one schema as the semantic source of truth.", "Prefer a first-order DSL over a general SQL engine when the problem needs only selection, predicates, and a limit.", "Represent type-sensitive cases explicitly, such as TextPredicate and NumberPredicate.", "Erase semantic types only after validation, when emitting residual target code.", "Keep the generated program free of the generator's parser and interpreter.", "Do not add a third Futamura projection unless it genuinely makes the system smaller and clearer."]
story.append(Paragraph("<br/>".join(f"{i}. {r}" for i, r in enumerate(rules, 1)), styles["BodyText"]))
story.append(Paragraph("Worked abstract shape", styles["Heading1"]))
story.append(Paragraph("For a query-driven data tool, the compact semantic normal form is:", styles["BodyText"]))
story.append(Paragraph("Query = (Predicate*, Limit)<br/>eval(Query, data) = take(limit, filter(data, conjunction(predicates)))", styles["CodeBlock"]))
story.append(Paragraph("The specializer receives only a validated query and emits a residual loop. This is the practical first Futamura projection:", styles["BodyText"]))
story.append(Paragraph("generic evaluator + fixed validated query -> residual program", styles["CodeBlock"]))
story.append(Paragraph("The method generalizes to parsers, validators, search tools, data transforms, protocol compilers, and configuration-driven programs. The central discipline is to make semantic boundaries explicit and avoid carrying static generality into the runtime artifact.", styles["Lead"]))
doc.build(story, onFirstPage=footer, onLaterPages=footer)
print(OUT)
