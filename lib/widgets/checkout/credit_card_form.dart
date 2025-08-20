import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'credit_card_model.dart';

class CreditCardForm extends StatefulWidget {
  CreditCardForm({
    Key? key,
    required this.cardNumber,
    required this.expiryYear,
    required this.expiryMonth,
    required this.cardHolderName,
    required this.cvvCode,
    this.obscureCvv = false,
    this.obscureNumber = false,
    required this.onCreditCardModelChange,
    required this.themeColor,
    this.textColor = Colors.black,
    this.cursorColor,
    this.cardHolderDecoration = const InputDecoration(
      labelText: 'Card holder',
    ),
    this.cardNumberDecoration = const InputDecoration(
      labelText: 'Card number',
      hintText: 'XXXX XXXX XXXX XXXX',
    ),
    this.expiryDateDecoration = const InputDecoration(
      labelText: 'Expired Date',
      hintText: 'MM/YY',
    ),
    this.cvvCodeDecoration = const InputDecoration(
      labelText: 'CVV',
      hintText: 'XXX',
    ),
    required this.formKey,
    this.onChange,
    this.cvvValidationMessage = 'Please input a valid CVV',
    this.dateValidationMessage = 'Please input a valid date',
    this.numberValidationMessage = 'Please input a valid number',
    this.isHolderNameVisible = true,
    this.isCardNumberVisible = true,
    this.isExpiryDateVisible = true,
    this.rtl = false,
    this.onCardEditComplete,
  }) : super(key: key);

  final String? cardNumber;
  int? expiryMonth, expiryYear;
  final String? cardHolderName;
  final String? cvvCode;
  final String cvvValidationMessage;
  final String dateValidationMessage;
  final String numberValidationMessage;
  final void Function(CreditCardModel) onCreditCardModelChange;
  final Color themeColor;
  final Color textColor;
  final Color? cursorColor;
  final bool obscureCvv;
  final bool obscureNumber;
  final bool isHolderNameVisible;
  final bool isCardNumberVisible;
  final bool isExpiryDateVisible;
  final bool rtl;
  final GlobalKey<FormState> formKey;
  Function? onChange;
  final InputDecoration cardNumberDecoration;
  final InputDecoration cardHolderDecoration;
  final InputDecoration expiryDateDecoration;
  final InputDecoration cvvCodeDecoration;
  final VoidCallback? onCardEditComplete;

  @override
  _CreditCardFormState createState() => _CreditCardFormState();
}

class _CreditCardFormState extends State<CreditCardForm> {
  late String cardNumber;
  late String expiryDate;
  late String cardHolderName;
  late String cvvCode;
  bool isCvvFocused = false;
  late Color themeColor;
  bool isRTL = false;
  late void Function(CreditCardModel) onCreditCardModelChange;
  late CreditCardModel creditCardModel;

  // Plain controllers (no external packages)
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvCodeController = TextEditingController();
  final TextEditingController _cardHolderNameController =
      TextEditingController();

  final FocusNode cvvFocusNode = FocusNode();
  final FocusNode expiryDateNode = FocusNode();
  final FocusNode cardHolderNode = FocusNode();

  void textFieldFocusDidChange() {
    creditCardModel.isCvvFocused = cvvFocusNode.hasFocus;
    onCreditCardModelChange(creditCardModel);
  }

  // --- Helpers ----------------------------------------------------------------

  String _formatCardNumber(String input) {
    final digits = _onlyWesternDigits(input);
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buf = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      buf.write(limited[i]);
      if ((i + 1) % 4 == 0 && i + 1 != limited.length) buf.write(' ');
    }
    return buf.toString();
  }

  String _formatExpiryFromParts(int? month, int? year) {
    if (month == null || year == null) return '';
    final mm = month.clamp(0, 99).toString().padLeft(2, '0');
    final yy = (year % 100).toString().padLeft(2, '0'); // <-- safe
    return '$mm/$yy';
  }

  String _onlyWesternDigits(String s) {
    // Map Arabic-Indic (0660–0669) and Eastern Arabic (06F0–06F9) to 0–9
    const ai = ['\u0660','\u0661','\u0662','\u0663','\u0664','\u0665','\u0666','\u0667','\u0668','\u0669'];
    const ea = ['\u06F0','\u06F1','\u06F2','\u06F3','\u06F4','\u06F5','\u06F6','\u06F7','\u06F8','\u06F9'];
    String out = s;
    for (int i = 0; i < 10; i++) {
      out = out.replaceAll(ai[i], i.toString());
      out = out.replaceAll(ea[i], i.toString());
    }
    return out.replaceAll(RegExp(r'\D'), ''); // keep digits only
  }

  void _updateModelAndNotify() {
    creditCardModel.cardNumber =
        _onlyWesternDigits(_cardNumberController.text); // no spaces
    creditCardModel.expiryDate = _expiryDateController.text; // MM/YY
    creditCardModel.cardHolderName = _cardHolderNameController.text;
    creditCardModel.cvvCode = _cvvCodeController.text;
    onCreditCardModelChange(creditCardModel);
  }

  void createCreditCardModel() {
    cardNumber = widget.cardNumber ?? '';
    expiryDate = _formatExpiryFromParts(widget.expiryMonth, widget.expiryYear);
    cardHolderName = widget.cardHolderName ?? '';
    cvvCode = widget.cvvCode ?? '';

    creditCardModel = CreditCardModel(
      cardNumber,
      expiryDate,
      cardHolderName,
      cvvCode,
      isCvvFocused,
    );
  }

  // --- Lifecycle --------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    isRTL = widget.rtl;

    createCreditCardModel();

    // Seed controllers with formatted initial values
    _cardNumberController.text = _formatCardNumber(cardNumber);
    _expiryDateController.text = expiryDate;
    _cvvCodeController.text = cvvCode;
    _cardHolderNameController.text = cardHolderName;

    onCreditCardModelChange = widget.onCreditCardModelChange;

    cvvFocusNode.addListener(textFieldFocusDidChange);

    // Listeners
    _cardNumberController.addListener(() {
      // Reformat as XXXX XXXX XXXX XXXX while typing
      final formatted = _formatCardNumber(_cardNumberController.text);
      if (_cardNumberController.text != formatted) {
        final selToEnd = formatted.length;
        _cardNumberController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: selToEnd),
        );
      }
      _updateModelAndNotify();
      if (widget.onChange != null) widget.onChange!(_cardNumberController.text);
    });

    _expiryDateController.addListener(() {
      _updateModelAndNotify();
    });

    _cardHolderNameController.addListener(() {
      _updateModelAndNotify();
    });

    _cvvCodeController.addListener(() {
      _updateModelAndNotify();
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cardHolderNameController.dispose();
    _cvvCodeController.dispose();

    cardHolderNode.dispose();
    cvvFocusNode.dispose();
    expiryDateNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    themeColor = widget.themeColor;
    super.didChangeDependencies();
  }

  // --- Validation -------------------------------------------------------------

  String? _validateCardNumber(String? value) {
    final digits = _onlyWesternDigits(value ?? '');
    if (digits.length != 16) {
      return widget.numberValidationMessage;
    }
    return null;
  }

  String? _validateExpiry(String? value) {
    final v = value ?? '';
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(v)) {
      return widget.dateValidationMessage;
    }
    final mm = int.tryParse(v.substring(0, 2)) ?? 0;
    final yy = int.tryParse(v.substring(3, 5)) ?? 0;
    if (mm < 1 || mm > 12) return widget.dateValidationMessage;

    final now = DateTime.now();
    final expYear = 2000 + yy;
    final exp = DateTime(expYear, mm); // first of exp month
    final cur = DateTime(now.year, now.month);
    if (exp.isBefore(cur)) return widget.dateValidationMessage;
    return null;
  }

  String? _validateCVV(String? value) {
    if ((value ?? '').length != 3) {
      return widget.cvvValidationMessage;
    }
    return null;
  }

  // --- Build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: themeColor.withOpacity(0.8),
        primaryColorDark: themeColor,
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          children: <Widget>[
            // Card number
            Visibility(
              visible: widget.isCardNumberVisible,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                margin: const EdgeInsets.only(left: 16, top: 16, right: 16),
                child: TextFormField(
                  controller: _cardNumberController,
                  textDirection: TextDirection.ltr, // force LTR for numeric
                  obscureText: widget.obscureNumber,
                  cursorColor: widget.cursorColor ?? themeColor,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.creditCardNumber],
                  decoration: widget.cardNumberDecoration,
                  inputFormatters: [
                    _ArabicToWesternDigitsFormatter(),
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
                    _CardNumberFormatterFormatter(maxDigits: 16),
                  ],
                  validator: _validateCardNumber,
                  onEditingComplete: () {
                    widget.onCardEditComplete?.call();
                    FocusScope.of(context).requestFocus(expiryDateNode);
                  },
                  onChanged: (String text) {
                    if (widget.onChange != null) widget.onChange!(text);
                  },
                  style: TextStyle(color: widget.textColor),
                ),
              ),
            ),

            // Expiry + CVV row
            Row(
              children: <Widget>[
                Visibility(
                  visible: widget.isExpiryDateVisible,
                  child: Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      margin:
                          const EdgeInsets.only(left: 16, top: 8, right: 16),
                      child: TextFormField(
                        controller: _expiryDateController,
                        textDirection: TextDirection.ltr,
                        cursorColor: widget.cursorColor ?? themeColor,
                        focusNode: expiryDateNode,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[
                          AutofillHints.creditCardExpirationDate
                        ],
                        decoration: widget.expiryDateDecoration,
                        inputFormatters: [
                          _ArabicToWesternDigitsFormatter(),
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          _ExpirySlashFormatter(), // makes MM/YY
                        ],
                        validator: _validateExpiry,
                        style: TextStyle(color: widget.textColor),
                        onEditingComplete: () {
                          FocusScope.of(context).requestFocus(cvvFocusNode);
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    margin: const EdgeInsets.only(left: 16, top: 8, right: 16),
                    child: TextFormField(
                      controller: _cvvCodeController,
                      textDirection: TextDirection.ltr,
                      focusNode: cvvFocusNode,
                      obscureText: widget.obscureCvv,
                      cursorColor: widget.cursorColor ?? themeColor,
                      keyboardType: TextInputType.number,
                      textInputAction: widget.isHolderNameVisible
                          ? TextInputAction.next
                          : TextInputAction.done,
                      autofillHints: const <String>[
                        AutofillHints.creditCardSecurityCode
                      ],
                      decoration: widget.cvvCodeDecoration,
                      inputFormatters: [
                        _ArabicToWesternDigitsFormatter(),
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: _validateCVV,
                      style: TextStyle(color: widget.textColor),
                      onEditingComplete: () {
                        if (widget.isHolderNameVisible) {
                          FocusScope.of(context).requestFocus(cardHolderNode);
                        } else {
                          FocusScope.of(context).unfocus();
                          onCreditCardModelChange(creditCardModel);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Holder name
            Visibility(
              visible: widget.isHolderNameVisible,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                margin: const EdgeInsets.only(left: 16, top: 8, right: 16),
                child: TextFormField(
                  controller: _cardHolderNameController,
                  cursorColor: widget.cursorColor ?? themeColor,
                  textDirection: widget.rtl ? TextDirection.rtl : TextDirection.ltr,
                  focusNode: cardHolderNode,
                  style: TextStyle(color: widget.textColor),
                  decoration: widget.cardHolderDecoration,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.creditCardName],
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
                    onCreditCardModelChange(creditCardModel);
                  },
                  validator: (String? value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Please enter card holder name';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= Input Formatters (no packages) =======================

/// Normalizes Arabic-Indic and Eastern Arabic digits to Western 0-9.
class _ArabicToWesternDigitsFormatter extends TextInputFormatter {
  static const _ai = ['\u0660','\u0661','\u0662','\u0663','\u0664','\u0665','\u0666','\u0667','\u0668','\u0669'];
  static const _ea = ['\u06F0','\u06F1','\u06F2','\u06F3','\u06F4','\u06F5','\u06F6','\u06F7','\u06F8','\u06F9'];

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String t = newValue.text;
    for (int i = 0; i < 10; i++) {
      t = t.replaceAll(_ai[i], i.toString());
      t = t.replaceAll(_ea[i], i.toString());
    }
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

/// Formats the card number as "#### #### #### ####" and limits to [maxDigits] digits.
class _CardNumberFormatterFormatter extends TextInputFormatter {
  _CardNumberFormatterFormatter({this.maxDigits = 16});
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > maxDigits ? digits.substring(0, maxDigits) : digits;

    final buf = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      buf.write(limited[i]);
      if ((i + 1) % 4 == 0 && i + 1 != limited.length) buf.write(' ');
    }
    final out = buf.toString();
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

/// Turns "MMYY" into "MM/YY" while typing (max 4 digits).
class _ExpirySlashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;

    String out;
    if (limited.length <= 2) {
      out = limited;
    } else {
      out = '${limited.substring(0, 2)}/${limited.substring(2)}';
    }

    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}
