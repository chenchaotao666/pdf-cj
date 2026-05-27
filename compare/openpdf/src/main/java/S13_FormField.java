import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S13_FormField {
    static final String FONT_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc,0";
    static final String IMG_DIR   = "../../examples/images/";
    static final String OUT_DIR   = "output/";

    static BaseFont CJK_BF;
    static BaseFont HELV_BF;
    static {
        try {
            CJK_BF  = BaseFont.createFont(FONT_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED);
            HELV_BF = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED);
        } catch (Exception e) { throw new RuntimeException(e); }
    }
    static Font cjk(float s)     { return new Font(CJK_BF, s); }
    static Font cjkBold(float s) { return new Font(CJK_BF, s, Font.BOLD); }
    static Font helv(float s)    { return new Font(HELV_BF, s); }

    public static void main(String[] args) throws Exception {
        new File(OUT_DIR).mkdirs();

        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s13_formfield.pdf"));
        doc.open();

        // Title
        Paragraph title = new Paragraph("S13: Form Field Demo", cjkBold(18));
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(20);
        doc.add(title);
        doc.add(new Paragraph("This PDF contains interactive form fields.", helv(11)));

        float yPos = 720;
        float labelX = 72;
        float fieldX = 200;
        float fieldW = 280;

        // 1. Text field (single line)
        try {
            doc.add(new Paragraph(" ", helv(4)));
            doc.add(new Paragraph("1. Text Field (single line):", helv(11)));
            Rectangle tfRect = new Rectangle(fieldX, yPos - 20, fieldX + fieldW, yPos);
            TextField tf = new TextField(writer, tfRect, "textField1");
            tf.setText("Default text value");
            tf.setFontSize(11);
            tf.setFont(HELV_BF);
            tf.setBorderColor(Color.GRAY);
            tf.setBackgroundColor(new Color(240, 248, 255));
            writer.addAnnotation(tf.getTextField());
            yPos -= 40;
        } catch (Exception e) {
            doc.add(new Paragraph("1. TextField error: " + e.getMessage(), helv(10)));
        }

        // 2. Multiline text field
        try {
            doc.add(new Paragraph("2. Text Field (multiline):", helv(11)));
            Rectangle mlRect = new Rectangle(fieldX, yPos - 60, fieldX + fieldW, yPos);
            TextField mlTf = new TextField(writer, mlRect, "multilineField");
            mlTf.setText("Line 1\nLine 2\nLine 3");
            mlTf.setFontSize(10);
            mlTf.setFont(HELV_BF);
            mlTf.setOptions(BaseField.MULTILINE);
            mlTf.setBorderColor(Color.GRAY);
            mlTf.setBackgroundColor(new Color(255, 255, 240));
            writer.addAnnotation(mlTf.getTextField());
            yPos -= 80;
        } catch (Exception e) {
            doc.add(new Paragraph("2. Multiline TextField error: " + e.getMessage(), helv(10)));
        }

        // 3. Checkbox (checked)
        // In OpenPDF 2.x RadioCheckField: use getFullField() for standalone checkbox
        try {
            doc.add(new Paragraph("3. Checkbox (checked):", helv(11)));
            Rectangle cbRect = new Rectangle(fieldX, yPos - 20, fieldX + 20, yPos);
            RadioCheckField rcChecked = new RadioCheckField(writer, cbRect, "checkbox1", "Yes");
            rcChecked.setChecked(true);
            rcChecked.setCheckType(RadioCheckField.TYPE_CHECK);
            rcChecked.setBorderColor(Color.BLACK);
            rcChecked.setBackgroundColor(Color.WHITE);
            writer.addAnnotation(rcChecked.getFullField());
            yPos -= 35;
        } catch (Exception e) {
            doc.add(new Paragraph("3. Checkbox error: " + e.getMessage(), helv(10)));
        }

        // 4. Checkbox (unchecked)
        try {
            doc.add(new Paragraph("4. Checkbox (unchecked):", helv(11)));
            Rectangle cbRect2 = new Rectangle(fieldX, yPos - 20, fieldX + 20, yPos);
            RadioCheckField rcUnchecked = new RadioCheckField(writer, cbRect2, "checkbox2", "No");
            rcUnchecked.setChecked(false);
            rcUnchecked.setCheckType(RadioCheckField.TYPE_CROSS);
            rcUnchecked.setBorderColor(Color.BLACK);
            rcUnchecked.setBackgroundColor(Color.WHITE);
            writer.addAnnotation(rcUnchecked.getFullField());
            yPos -= 35;
        } catch (Exception e) {
            doc.add(new Paragraph("4. Checkbox unchecked error: " + e.getMessage(), helv(10)));
        }

        // 5. Radio button group — use getKidField() for radio group kids
        try {
            doc.add(new Paragraph("5. Radio Button Group:", helv(11)));
            PdfFormField radioGroup = PdfFormField.createRadioButton(writer, false);
            radioGroup.setFieldName("radioGroup1");

            String[] radioVals = {"Option A", "Option B", "Option C"};
            for (int i = 0; i < radioVals.length; i++) {
                Rectangle rbRect = new Rectangle(fieldX, yPos - 18 - i * 25, fieldX + 18, yPos - i * 25);
                RadioCheckField rb = new RadioCheckField(writer, rbRect, null, radioVals[i]);
                rb.setChecked(i == 0);  // first one selected
                rb.setCheckType(RadioCheckField.TYPE_CIRCLE);
                rb.setBorderColor(Color.BLACK);
                rb.setBackgroundColor(Color.WHITE);
                radioGroup.addKid(rb.getKidField());
            }
            writer.addAnnotation(radioGroup);
            yPos -= 90;
        } catch (Exception e) {
            doc.add(new Paragraph("5. Radio button error: " + e.getMessage(), helv(10)));
        }

        // 6. Combo box (dropdown) — use BaseField.EDIT flag for editable combo
        try {
            doc.add(new Paragraph("6. Combo Box (dropdown):", helv(11)));
            Rectangle comboRect = new Rectangle(fieldX, yPos - 20, fieldX + fieldW, yPos);
            String[] comboItems = {"-- Select --", "Apple", "Banana", "Cherry", "Date", "Elderberry"};
            TextField comboTf = new TextField(writer, comboRect, "comboField1");
            comboTf.setChoices(comboItems);
            comboTf.setChoiceSelection(0);
            // TextField.COMBO not available — use getComboField() directly (it adds COMBO flag internally)
            comboTf.setFontSize(10);
            comboTf.setFont(HELV_BF);
            comboTf.setBorderColor(Color.GRAY);
            writer.addAnnotation(comboTf.getComboField());
            yPos -= 35;
        } catch (Exception e) {
            doc.add(new Paragraph("6. Combo box error: " + e.getMessage(), helv(10)));
        }

        // 7. List box — use BaseField.MULTISELECT
        try {
            doc.add(new Paragraph("7. List Box:", helv(11)));
            Rectangle listRect = new Rectangle(fieldX, yPos - 70, fieldX + fieldW, yPos);
            String[] listItems = {"Red", "Green", "Blue", "Yellow", "Purple"};
            TextField listTf = new TextField(writer, listRect, "listField1");
            listTf.setChoices(listItems);
            listTf.setChoiceSelection(1);
            listTf.setOptions(BaseField.MULTISELECT);
            listTf.setFontSize(10);
            listTf.setFont(HELV_BF);
            listTf.setBorderColor(Color.GRAY);
            writer.addAnnotation(listTf.getListField());
            yPos -= 90;
        } catch (Exception e) {
            doc.add(new Paragraph("7. List box error: " + e.getMessage(), helv(10)));
        }

        // 8. Push button
        try {
            doc.add(new Paragraph("8. Push Button:", helv(11)));
            Rectangle btnRect = new Rectangle(fieldX, yPos - 24, fieldX + 120, yPos);
            PdfFormField btn = PdfFormField.createPushButton(writer);
            btn.setFieldName("pushButton1");
            btn.setWidget(btnRect, PdfAnnotation.HIGHLIGHT_PUSH);
            PdfAppearance ap = writer.getDirectContent().createAppearance(120, 24);
            ap.setColorFill(new Color(200, 200, 240));
            ap.rectangle(0, 0, 120, 24);
            ap.fill();
            ap.setColorFill(Color.BLACK);
            ap.beginText();
            ap.setFontAndSize(HELV_BF, 10);
            ap.setTextMatrix(10, 8);
            ap.showText("Click Me!");
            ap.endText();
            btn.setAppearance(PdfAnnotation.APPEARANCE_NORMAL, ap);
            writer.addAnnotation(btn);
            yPos -= 40;
        } catch (Exception e) {
            doc.add(new Paragraph("8. Push button error: " + e.getMessage(), helv(10)));
        }

        doc.close();
        System.out.println("S13 done: " + OUT_DIR + "java_s13_formfield.pdf");
    }
}
