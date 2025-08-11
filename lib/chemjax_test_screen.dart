import 'package:flutter/material.dart';
import 'chemjax_widget.dart';

/// Test screen for demonstrating ChemJAX chemical formula rendering
class ChemJAXTestScreen extends StatelessWidget {
  const ChemJAXTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChemJAX Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🧪 ChemJAX Chemical Formula Rendering Test',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            
            _buildTestSection(
              context,
              'Basic Molecules',
              [
                r'$\ce{H2O}$', // Water
                r'$\ce{CO2}$', // Carbon dioxide
                r'$\ce{CH4}$', // Methane
                r'$\ce{NH3}$', // Ammonia
                r'$\ce{H2SO4}$', // Sulfuric acid
              ],
            ),
            
            _buildTestSection(
              context,
              'Chemical Reactions',
              [
                r'$\ce{CH4 + 2O2 -> CO2 + 2H2O}$', // Combustion
                r'$\ce{HCl + NaOH -> NaCl + H2O}$', // Acid-base
                r'$\ce{6CO2 + 6H2O ->[light] C6H12O6 + 6O2}$', // Photosynthesis
                r'$\ce{N2 + 3H2 <=> 2NH3}$', // Haber process
              ],
            ),
            
            _buildTestSection(
              context,
              'Ions and States',
              [
                r'$\ce{Na+}$', // Sodium ion
                r'$\ce{Cl-}$', // Chloride ion
                r'$\ce{SO4^2-}$', // Sulfate ion
                r'$\ce{H2O(l)}$', // Liquid water
                r'$\ce{CO2(g)}$', // Gaseous CO2
                r'$\ce{NaCl(s)}$', // Solid salt
              ],
            ),
            
            _buildTestSection(
              context,
              'Complex Structures',
              [
                r'$\ce{C6H12O6}$', // Glucose
                r'$\ce{Ca(OH)2}$', // Calcium hydroxide
                r'$\ce{Al2(SO4)3}$', // Aluminum sulfate
                r'$\ce{C8H10N4O2}$', // Caffeine
                r'$\ce{C6H6}$', // Benzene
              ],
            ),
            
            const SizedBox(height: 32),
            Text(
              '📝 Usage in Chat:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask the AI about chemistry and it will automatically render formulas:',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• "What is the formula for water?" → \$\\ce{H2O}\$',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    '• "Show me photosynthesis reaction" → \$\\ce{6CO2 + 6H2O ->[light] C6H12O6 + 6O2}\$',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    '• "What are common acids?" → \$\\ce{HCl}\$, \$\\ce{H2SO4}\$, \$\\ce{HNO3}\$',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection(BuildContext context, String title, List<String> formulas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...formulas.map((formula) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ChemJAXWidget(
              formula: formula,
              width: double.infinity,
              height: 60,
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        )),
        const SizedBox(height: 24),
      ],
    );
  }
}