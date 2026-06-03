import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import java.awt.Color;
import java.io.*;
import java.nio.file.*;

public class S13_FormField {
    static final String FONT_PATH = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc,0";
    static final String OUT_DIR   = "output/";

    static BaseFont CJK_BF;
    static BaseFont HELV_BF;
    static {
        try {
            CJK_BF  = BaseFont.createFont(FONT_PATH, BaseFont.IDENTITY_H, BaseFont.EMBEDDED);
            HELV_BF = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED);
        } catch (Exception e) { throw new RuntimeException(e); }
    }

    static void label(PdfContentByte cb, float x, float y, String text) throws Exception {
        cb.beginText();
        cb.setFontAndSize(HELV_BF, 11);
        cb.setColorFill(Color.BLACK);
        cb.setTextMatrix(x, y);
        cb.showText(text);
        cb.endText();
    }

    public static void main(String[] args) throws Exception {
        new File(OUT_DIR).mkdirs();

        Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
        PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(OUT_DIR + "java_s13_formfield.pdf"));
        doc.open();

        PdfContentByte cb = writer.getDirectContent();

        // Title
        cb.beginText();
        cb.setFontAndSize(CJK_BF, 18);
        cb.setColorFill(Color.BLACK);
        cb.showTextAligned(PdfContentByte.ALIGN_CENTER, "S13: Form Field Demo", 297, 780, 0);
        cb.endText();

        label(cb, 72, 755, "Each type: (a) default settings  (b) custom settings.");

        float labelX = 72;
        float fieldX = 200;
        float fieldW = 280;
        float yPos = 720;

        // ---- 1. Text Field ----
        label(cb, labelX, yPos + 5, "1a. Text Field (default):");
        try {
            TextField tf1a = new TextField(writer, new Rectangle(fieldX, yPos - 18, fieldX + fieldW, yPos), "tf_default");
            tf1a.setText("Default text");
            writer.addAnnotation(tf1a.getTextField());
        } catch (Exception e) { label(cb, labelX, yPos - 10, "error: " + e.getMessage()); }
        yPos -= 32;

        label(cb, labelX, yPos + 5, "1b. Text Field (custom: size=11, gray border, light-blue bg):");
        try {
            TextField tf1b = new TextField(writer, new Rectangle(fieldX, yPos - 18, fieldX + fieldW, yPos), "tf_custom");
            tf1b.setText("Custom text");
            tf1b.setFontSize(11);
            tf1b.setFont(HELV_BF);
            tf1b.setBorderColor(Color.GRAY);
            tf1b.setBackgroundColor(new Color(240, 248, 255));
            writer.addAnnotation(tf1b.getTextField());
        } catch (Exception e) { label(cb, labelX, yPos - 10, "error: " + e.getMessage()); }
        yPos -= 38;

        // ---- 2. Multiline Text Field ----
        label(cb, labelX, yPos + 5, "2a. Multiline (default):");
        try {
            TextField tf2a = new TextField(writer, new Rectangle(fieldX, yPos - 42, fieldX + fieldW, yPos), "ml_default");
            tf2a.setText("Line 1\nLine 2\nLine 3");
            tf2a.setOptions(BaseField.MULTILINE);
            writer.addAnnotation(tf2a.getTextField());
        } catch (Exception e) { label(cb, labelX, yPos - 10, "error: " + e.getMessage()); }
        yPos -= 55;

        label(cb, labelX, yPos + 5, "2b. Multiline (custom: size=10, gray border, light-yellow bg):");
        try {
            TextField tf2b = new TextField(writer, new Rectangle(fieldX, yPos - 42, fieldX + fieldW, yPos), "ml_custom");
            tf2b.setText("Line 1\nLine 2\nLine 3");
            tf2b.setFontSize(10);
            tf2b.setFont(HELV_BF);
            tf2b.setOptions(BaseField.MULTILINE);
            tf2b.setBorderColor(Color.GRAY);
            tf2b.setBackgroundColor(new Color(255, 255, 240));
            writer.addAnnotation(tf2b.getTextField());
        } catch (Exception e) { label(cb, labelX, yPos - 10, "error: " + e.getMessage()); }
        yPos -= 58;

        // ---- 3. Checkbox ----
        label(cb, labelX, yPos + 5, "3a. Checkbox (default, checked):");
        try {
            RadioCheckField cb3a = new RadioCheckField(writer,
                    new Rectangle(fieldX, yPos - 16, fieldX + 16, yPos), "cb_default", "Yes");
            cb3a.setChecked(true);
            cb3a.setCheckType(RadioCheckField.TYPE_CHECK);
            writer.addAnnotation(cb3a.getFullField());
        } catch (Exception e) { label(cb, labelX, yPos - 10, "error: " + e.getMessage()); }
        yPos -= 28;

        label(cb, labelX, yPos + 5, "3b. Checkbox (custom: black border, white bg, unchecked):");
        try {
            RadioCheckField cb3b = new RadioCheckField(writer,
                    new Rectangle(fieldX, yPos - 16, fieldX + 16, yPos), "cb_custom", "No");
            cb3b.setChecked(false);
            cb3b.setCheckType(RadioCheckField.TYPE_CHECK);
            cb3b.setBorderColor(Color.BLACK);
            cb3b.setBackgroundColor(Color.WHITE);
            writer.addAnnotation(cb3b.getFullField());
        } catch (Exception e) { label(cb, labelX, yPos - 10, "error: " + e.getMessage()); }
        yPos -= 35;

        // ---- 4. Radio Button Group ----
        label(cb, labelX, yPos + 5, "4a. Radio Group (default):");
        try {
            PdfFormField rg4a = PdfFormField.createRadioButton(writer, false);
            rg4a.setFieldName("radio_default");
            String[] opts4a = {"A", "B", "C"};
            for (int i = 0; i < opts4a.length; i++) {
                Rectangle r = new Rectangle(fieldX, yPos - 16 - i * 18, fieldX + 16, yPos - i * 18);
                RadioCheckField rb = new RadioCheckField(writer, r, null, opts4a[i]);
                rb.setChecked(i == 0);
                rb.setCheckType(RadioCheckField.TYPE_CIRCLE);
                rg4a.addKid(rb.getKidField());
            }
            writer.addAnnotation(rg4a);
        } catch (Exception e) { label(cb, labelX, yPos - 10, "error: " + e.getMessage()); }
        yPos -= 65;

        label(cb, labelX, yPos + 5, "4b. Radio Group (custom: black border, white bg):");
        try {
            PdfFormField rg4b = PdfFormField.createRadioButton(writer, false);
            rg4b.setFieldName("radio_custom");
            String[] opts4b = {"A", "B", "C"};
            for (int i = 0; i < opts4b.length; i++) {
                Rectangle r = new Rectangle(fieldX, yPos - 16 - i * 18, fieldX + 16, yPos - i * 18);
                RadioCheckField rb = new RadioCheckField(writer, r, null, opts4b[i]);
                rb.setChecked(i == 0);
                rb.setCheckType(RadioCheckField.TYPE_CIRCLE);
                rb.setBorderColor(Color.BLACK);
                rb.setBackgroundColor(Color.WHITE);
                rg4b.addKid(rb.getKidField());
            }
            writer.addAnnotation(rg4b);
        } catch (Exception e) { label(cb, labelX, yPos - 10, "error: " + e.getMessage()); }
        yPos -= 68;

        // ---- 5. Combo Box ----
        label(cb, labelX, yPos + 5, "5a. Combo Box (default):");
        try {
            TextField cb5a = new TextField(writer,
                    new Rectangle(fieldX, yPos - 18, fieldX + fieldW, yPos), "combo_default");
            cb5a.setChoices(new String[]{"Apple", "Banana", "Cherry"});
            cb5a.setChoiceSelection(0);
            cb5a.setFontSize(10);
            cb5a.setFont(HELV_BF);
            writer.addAnnotation(cb5a.getComboField());
        } catch (Exception e) { label(cb, labelX, yPos - 10, "error: " + e.getMessage()); }
        yPos -= 30;

        label(cb, labelX, yPos + 5, "5b. Combo Box (custom: size=10, gray border):");
        try {
            TextField cb5b = new TextField(writer,
                    new Rectangle(fieldX, yPos - 18, fieldX + fieldW, yPos), "combo_custom");
            cb5b.setChoices(new String[]{"Apple", "Banana", "Cherry"});
            cb5b.setChoiceSelection(0);
            cb5b.setFontSize(10);
            cb5b.setFont(HELV_BF);
            cb5b.setBorderColor(Color.GRAY);
            writer.addAnnotation(cb5b.getComboField());
        } catch (Exception e) { label(cb, labelX, yPos - 10, "error: " + e.getMessage()); }
        yPos -= 35;

        // ---- 6. List Box ----
        label(cb, labelX, yPos + 5, "6a. List Box (default):");
        try {
            TextField lb6a = new TextField(writer,
                    new Rectangle(fieldX, yPos - 48, fieldX + fieldW, yPos), "list_default");
            lb6a.setChoices(new String[]{"Red", "Green", "Blue"});
            lb6a.setChoiceSelection(0);
            lb6a.setFontSize(10);
            lb6a.setFont(HELV_BF);
            writer.addAnnotation(lb6a.getListField());
        } catch (Exception e) { label(cb, labelX, yPos - 10, "error: " + e.getMessage()); }
        yPos -= 62;

        label(cb, labelX, yPos + 5, "6b. List Box (custom: multiselect, gray border):");
        try {
            TextField lb6b = new TextField(writer,
                    new Rectangle(fieldX, yPos - 48, fieldX + fieldW, yPos), "list_custom");
            lb6b.setChoices(new String[]{"Red", "Green", "Blue"});
            lb6b.setChoiceSelection(1);
            lb6b.setOptions(BaseField.MULTISELECT);
            lb6b.setFontSize(10);
            lb6b.setFont(HELV_BF);
            lb6b.setBorderColor(Color.GRAY);
            writer.addAnnotation(lb6b.getListField());
        } catch (Exception e) { label(cb, labelX, yPos - 10, "error: " + e.getMessage()); }
        yPos -= 65;

        // ---- 7. Push Button ----
        label(cb, labelX, yPos + 5, "7a. Push Button (default: outline):");
        try {
            PdfFormField btn7a = PdfFormField.createPushButton(writer);
            btn7a.setFieldName("btn_default");
            btn7a.setWidget(new Rectangle(fieldX, yPos - 20, fieldX + 120, yPos), PdfAnnotation.HIGHLIGHT_PUSH);
            PdfAppearance ap7a = writer.getDirectContent().createAppearance(120, 20);
            ap7a.rectangle(0, 0, 120, 20);
            ap7a.stroke();
            ap7a.beginText();
            ap7a.setFontAndSize(HELV_BF, 10);
            ap7a.setTextMatrix(10, 6);
            ap7a.showText("Click Me!");
            ap7a.endText();
            btn7a.setAppearance(PdfAnnotation.APPEARANCE_NORMAL, ap7a);
            writer.addAnnotation(btn7a);
        } catch (Exception e) { label(cb, labelX, yPos - 10, "error: " + e.getMessage()); }
        yPos -= 32;

        label(cb, labelX, yPos + 5, "7b. Push Button (custom: blue bg):");
        try {
            PdfFormField btn7b = PdfFormField.createPushButton(writer);
            btn7b.setFieldName("btn_custom");
            btn7b.setWidget(new Rectangle(fieldX, yPos - 20, fieldX + 120, yPos), PdfAnnotation.HIGHLIGHT_PUSH);
            PdfAppearance ap7b = writer.getDirectContent().createAppearance(120, 20);
            ap7b.setColorFill(new Color(200, 200, 240));
            ap7b.rectangle(0, 0, 120, 20);
            ap7b.fill();
            ap7b.setColorFill(Color.BLACK);
            ap7b.beginText();
            ap7b.setFontAndSize(HELV_BF, 10);
            ap7b.setTextMatrix(10, 6);
            ap7b.showText("Click Me!");
            ap7b.endText();
            btn7b.setAppearance(PdfAnnotation.APPEARANCE_NORMAL, ap7b);
            writer.addAnnotation(btn7b);
        } catch (Exception e) { label(cb, labelX, yPos - 10, "error: " + e.getMessage()); }

        doc.close();
        System.out.println("S13 done: " + OUT_DIR + "java_s13_formfield.pdf");
    }
}
