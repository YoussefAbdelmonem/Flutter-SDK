import 'package:flutter/material.dart';

import 'credit_card_model.dart';
import 'credit_card_widget.dart';

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

  late MaskedTextController _cardNumberController;
  late MaskedTextController _expiryDateController;
  late MaskedTextController _cvvCodeController;
  late TextEditingController _cardHolderNameController;

  FocusNode cvvFocusNode = FocusNode();
  FocusNode expiryDateNode = FocusNode();
  FocusNode cardHolderNode = FocusNode();

  void textFieldFocusDidChange() {
    creditCardModel.isCvvFocused = cvvFocusNode.hasFocus;
    onCreditCardModelChange(creditCardModel);
  }

  void createCreditCardModel() {
    cardNumber = widget.cardNumber ?? '';
    expiryDate =
        (widget.expiryMonth != null && widget.expiryYear != null)
            ? '${widget.expiryMonth!.toString().padLeft(2, '0')}/${widget.expiryYear!.toString().substring(2)}'
            : '';
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

  @override
  void initState() {
    super.initState();
    isRTL = widget.rtl;

    // formatters with strict masks
    _cardNumberController = MaskedTextController(mask: '0000 0000 0000 0000');
    _expiryDateController = MaskedTextController(mask: '00/00');
    _cvvCodeController = MaskedTextController(mask: '000');
    _cardHolderNameController = TextEditingController();

    createCreditCardModel();
    onCreditCardModelChange = widget.onCreditCardModelChange;

    cvvFocusNode.addListener(textFieldFocusDidChange);

    _cardNumberController.addListener(() {
      setState(() {
        cardNumber = _cardNumberController.text.replaceAll(' ', '');
        creditCardModel.cardNumber = cardNumber;
        onCreditCardModelChange(creditCardModel);
      });
    });

    _expiryDateController.addListener(() {
      setState(() {
        expiryDate = _expiryDateController.text;
        creditCardModel.expiryDate = expiryDate;
        onCreditCardModelChange(creditCardModel);
      });
    });

    _cardHolderNameController.addListener(() {
      setState(() {
        cardHolderName = _cardHolderNameController.text;
        creditCardModel.cardHolderName = cardHolderName;
        onCreditCardModelChange(creditCardModel);
      });
    });

    _cvvCodeController.addListener(() {
      setState(() {
        cvvCode = _cvvCodeController.text;
        creditCardModel.cvvCode = cvvCode;
        onCreditCardModelChange(creditCardModel);
      });
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvCodeController.dispose();
    _cardHolderNameController.dispose();

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
                  textDirection: TextDirection.ltr,
                  obscureText: widget.obscureNumber,
                  cursorColor: widget.cursorColor ?? themeColor,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.creditCardNumber],
                  decoration: widget.cardNumberDecoration,
                  validator: (value) {
                    final clean = value?.replaceAll(' ', '') ?? '';
                    if (clean.length != 16) {
                      return widget.numberValidationMessage;
                    }
                    return null;
                  },
                  onEditingComplete: () {
                    widget.onCardEditComplete?.call();
                    FocusScope.of(context).requestFocus(expiryDateNode);
                  },
                  onChanged: (text) => widget.onChange?.call(text),
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
                      margin: const EdgeInsets.only(left: 16, top: 8, right: 16),
                      child: TextFormField(
                        controller: _expiryDateController,
                        textDirection: TextDirection.ltr,
                        focusNode: expiryDateNode,
                        cursorColor: widget.cursorColor ?? themeColor,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.creditCardExpirationDate
                        ],
                        decoration: widget.expiryDateDecoration,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return widget.dateValidationMessage;
                          }
                          final parts = value.split('/');
                          if (parts.length != 2) {
                            return widget.dateValidationMessage;
                          }
                          final month = int.tryParse(parts[0]) ?? 0;
                          final year = int.tryParse(parts[1]) ?? 0;
                          if (month < 1 || month > 12) {
                            return widget.dateValidationMessage;
                          }
                          final now = DateTime.now();
                          final fourDigitYear = 2000 + year;
                          final cardDate = DateTime(fourDigitYear, month + 1);
                          if (cardDate.isBefore(now)) {
                            return widget.dateValidationMessage;
                          }
                          return null;
                        },
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
                      autofillHints: const [AutofillHints.creditCardSecurityCode],
                      decoration: widget.cvvCodeDecoration,
                      validator: (value) {
                        if (value == null || value.length != 3) {
                          return widget.cvvValidationMessage;
                        }
                        return null;
                      },
                      style: TextStyle(color: widget.textColor),
                      onChanged: (text) => setState(() => cvvCode = text),
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
                  focusNode: cardHolderNode,
                  cursorColor: widget.cursorColor ?? themeColor,
                  textDirection: Directionality.of(context),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.creditCardName],
                  decoration: widget.cardHolderDecoration,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 3) {
                      return 'Please enter card holder name';
                    }
                    return null;
                  },
                  style: TextStyle(color: widget.textColor),
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
                    onCreditCardModelChange(creditCardModel);
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
