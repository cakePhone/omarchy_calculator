import 'package:flutter_omarchy/flutter_omarchy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

void main() async {
  await Omarchy.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OmarchyApp(home: const CalculatorApp());
  }
}

class CalculationEntry {
  final String expression;
  final String result;

  CalculationEntry({required this.expression, required this.result});
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<CalculationEntry> _history = [];
  String _currentPreview = '';
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _currentPreview = _calculatePreview(_controller.text);
    });
  }

  String _calculatePreview(String expression) {
    if (expression.trim().isEmpty) return '';

    try {
      double result = _evaluateExpression(expression);

      if (result.isNaN || result.isInfinite) return '';

      // Format result
      if (result == result.toInt()) {
        return result.toInt().toString();
      } else {
        return result
            .toStringAsFixed(6)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
      }
    } catch (e) {
      return '';
    }
  }

  double _evaluateExpression(String expression) {
    try {
      // Basic expression evaluation - replace functions first
      String processed = expression.toLowerCase();

      // Replace functions with their values
      processed = processed.replaceAllMapped(RegExp(r'sin\(([^)]+)\)'), (
        match,
      ) {
        double value = double.parse(match.group(1)!);
        return math.sin(value * math.pi / 180).toString(); // degrees
      });

      processed = processed.replaceAllMapped(RegExp(r'cos\(([^)]+)\)'), (
        match,
      ) {
        double value = double.parse(match.group(1)!);
        return math.cos(value * math.pi / 180).toString();
      });

      processed = processed.replaceAllMapped(RegExp(r'tan\(([^)]+)\)'), (
        match,
      ) {
        double value = double.parse(match.group(1)!);
        return math.tan(value * math.pi / 180).toString();
      });

      processed = processed.replaceAllMapped(RegExp(r'log\(([^)]+)\)'), (
        match,
      ) {
        double value = double.parse(match.group(1)!);
        return (math.log(value) / math.ln10).toString();
      });

      processed = processed.replaceAllMapped(RegExp(r'ln\(([^)]+)\)'), (match) {
        double value = double.parse(match.group(1)!);
        return math.log(value).toString();
      });

      processed = processed.replaceAllMapped(RegExp(r'sqrt\(([^)]+)\)'), (
        match,
      ) {
        double value = double.parse(match.group(1)!);
        return math.sqrt(value).toString();
      });

      // Replace constants
      processed = processed.replaceAll('pi', math.pi.toString());
      processed = processed.replaceAll('e', math.e.toString());

      // Basic arithmetic evaluation
      return _evaluateArithmetic(processed);
    } catch (e) {
      return double.nan;
    }
  }

  double _evaluateArithmetic(String expression) {
    expression = expression.replaceAll(' ', '');

    // Simple left-to-right evaluation for now
    // In production, you'd want proper operator precedence
    List<String> tokens = [];
    String current = '';

    for (int i = 0; i < expression.length; i++) {
      String char = expression[i];
      if ('+-*/'.contains(char)) {
        if (current.isNotEmpty) {
          tokens.add(current);
          current = '';
        }
        tokens.add(char);
      } else {
        current += char;
      }
    }
    if (current.isNotEmpty) tokens.add(current);

    if (tokens.isEmpty) return 0;
    if (tokens.length == 1) return double.parse(tokens[0]);

    double result = double.parse(tokens[0]);

    for (int i = 1; i < tokens.length; i += 2) {
      if (i + 1 >= tokens.length) break;

      String operator = tokens[i];
      double operand = double.parse(tokens[i + 1]);

      switch (operator) {
        case '+':
          result += operand;
          break;
        case '-':
          result -= operand;
          break;
        case '*':
          result *= operand;
          break;
        case '/':
          if (operand == 0) throw Exception('Division by zero');
          result /= operand;
          break;
      }
    }

    return result;
  }

  void _submitCalculation() {
    String expression = _controller.text.trim();
    if (expression.isEmpty) return;

    String result = _calculatePreview(expression);
    if (result.isNotEmpty) {
      setState(() {
        _history.add(CalculationEntry(expression: expression, result: result));
        _controller.clear();
        _currentPreview = '';
      });

      // Auto-scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _insertText(String text) {
    final currentText = _controller.text;
    final selection = _controller.selection;
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    _controller.value = _controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + text.length),
    );
  }

  void _clearInput() {
    _controller.clear();
  }

  void _toggleButtons() {
    setState(() {
      _showButtons = !_showButtons;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OmarchyTheme.of(context);

    return OmarchyScaffold(
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            // Ctrl+B or F1 to toggle button drawer
            if ((event.logicalKey == LogicalKeyboardKey.keyB &&
                    HardwareKeyboard.instance.isControlPressed) ||
                event.logicalKey == LogicalKeyboardKey.f1) {
              _toggleButtons();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 800,
              minWidth: 400,
              minHeight: 600,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              children: [
                // Main content
                Column(
                  children: [
                    // Minimal title
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Calculator',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          color: theme.colors.normal[AnsiColor.white],
                        ),
                      ),
                    ),

                    // History and input area
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _history.length + 1, // +1 for current input
                        itemBuilder: (context, index) {
                          if (index < _history.length) {
                            // Previous calculations
                            final entry = _history[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Expression
                                  Text(
                                    entry.expression,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          theme.colors.normal[AnsiColor.white],
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Result (right-aligned, larger)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      entry.result,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: theme
                                            .colors
                                            .normal[AnsiColor.white],
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Current input
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: Stack(
                                children: [
                                  // Clean input field (no borders)
                                  Material(
                                    color: Colors.transparent,
                                    child: TextField(
                                      controller: _controller,
                                      focusNode: _focusNode,
                                      autofocus: true,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: theme
                                            .colors
                                            .normal[AnsiColor.white],
                                        fontFamily: 'monospace',
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Enter calculation...',
                                        hintStyle: TextStyle(
                                          color: theme
                                              .colors
                                              .bright[AnsiColor.black],
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onSubmitted: (_) => _submitCalculation(),
                                    ),
                                  ),
                                  // Ghost preview (appears after cursor)
                                  if (_currentPreview.isNotEmpty)
                                    Positioned(
                                      left:
                                          _getTextWidth(_controller.text, 16) +
                                          8,
                                      top:
                                          8, // Center with input text (padding adjustment)
                                      child: Text(
                                        '= $_currentPreview',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: theme
                                              .colors
                                              .bright[AnsiColor.black],
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),

                // Sliding button panel
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  bottom: _showButtons
                      ? 0
                      : -300, // Remove offset since button is on the side
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: Numbers
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildButton('7', () => _insertText('7')),
                            _buildButton('8', () => _insertText('8')),
                            _buildButton('9', () => _insertText('9')),
                            _buildButton('÷', () => _insertText('/')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row 2
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildButton('4', () => _insertText('4')),
                            _buildButton('5', () => _insertText('5')),
                            _buildButton('6', () => _insertText('6')),
                            _buildButton('×', () => _insertText('*')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row 3
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildButton('1', () => _insertText('1')),
                            _buildButton('2', () => _insertText('2')),
                            _buildButton('3', () => _insertText('3')),
                            _buildButton('-', () => _insertText('-')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row 4
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildButton('0', () => _insertText('0')),
                            _buildButton('.', () => _insertText('.')),
                            _buildButton('C', _clearInput),
                            _buildButton('+', () => _insertText('+')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row 5: Functions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildButton('sin(', () => _insertText('sin(')),
                            _buildButton('cos(', () => _insertText('cos(')),
                            _buildButton('√', () => _insertText('sqrt(')),
                            _buildButton('=', _submitCalculation),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Toggle button that follows the panel upwards
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  bottom: _showButtons
                      ? 300
                      : 20, // Follow the panel upwards from bottom
                  right: 20, // Keep right-aligned
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: OmarchyButton(
                      onPressed: _toggleButtons,
                      child: Icon(
                        _showButtons
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: theme.colors.bright[AnsiColor.green],
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ), // Stack
          ), // Container
        ), // Center
      ), // Focus
    ); // OmarchyScaffold
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    final theme = OmarchyTheme.of(context);

    // Color code the buttons based on their function
    Color getButtonColor() {
      switch (text) {
        case '+':
        case '-':
        case '×':
        case '÷':
        case '=':
          return theme.colors.bright[AnsiColor.cyan]; // Operations in cyan
        case 'C':
          return theme.colors.bright[AnsiColor.red]; // Clear in red
        case 'sin(':
        case 'cos(':
        case '√':
          return theme.colors.bright[AnsiColor.magenta]; // Functions in magenta
        case '.':
          return theme.colors.bright[AnsiColor.yellow]; // Decimal in yellow
        default:
          return theme.colors.normal[AnsiColor.white]; // Numbers in white
      }
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 48,
        child: OmarchyButton(
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: getButtonColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  double _getTextWidth(String text, double fontSize) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontFamily: 'monospace'),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    return textPainter.size.width;
  }
}
