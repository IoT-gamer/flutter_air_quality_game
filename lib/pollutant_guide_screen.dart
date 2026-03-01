import 'package:flutter/material.dart';

class PollutantInfo {
  final String name;
  final String acronym;
  final String assetPath;
  final String description;
  final String healthEffects;
  final Color themeColor;

  PollutantInfo({
    required this.name,
    required this.acronym,
    required this.assetPath,
    required this.description,
    required this.healthEffects,
    required this.themeColor,
  });
}

final List<PollutantInfo> pollutantDatabase = [
  PollutantInfo(
    name: 'Ultrafine Particles',
    acronym: 'PM 1.0',
    assetPath: 'assets/images/pm1/pm1.png',
    description:
        'Extremely tiny airborne particles less than 1 micrometer wide.',
    healthEffects:
        'Small enough to pass directly through the lungs into the bloodstream, potentially affecting organs and the cardiovascular system.',
    themeColor: Colors.purpleAccent,
  ),
  PollutantInfo(
    name: 'Fine Particulate Matter',
    acronym: 'PM 2.5',
    assetPath: 'assets/images/pm2p5/pm2p5.png',
    description:
        'Common combustion particles from car exhaust, wildfires, and power plants.',
    healthEffects:
        'Causes respiratory irritation, worsens asthma, and is linked to long-term heart and lung diseases.',
    themeColor: Colors.pinkAccent,
  ),
  PollutantInfo(
    name: 'Coarse Particulates',
    acronym: 'PM 4.0 & PM 10.0',
    assetPath: 'assets/images/pm10/pm10.png',
    description:
        'Larger dust, pollen, and mold particles that float in the air.',
    healthEffects:
        'Irritates the eyes, nose, and throat. Can trigger severe allergy and asthma attacks when inhaled.',
    themeColor: Colors.teal,
  ),
  PollutantInfo(
    name: 'Volatile Organic Compounds',
    acronym: 'VOC',
    assetPath: 'assets/images/voc/voc.png',
    description:
        'Gases emitted from everyday items like cleaning supplies, paint, and new furniture (off-gassing).',
    healthEffects:
        'Short-term exposure causes headaches and dizziness. Long-term exposure can damage the liver, kidneys, and central nervous system.',
    themeColor: Colors.deepPurple,
  ),
  PollutantInfo(
    name: 'Nitrogen Oxides',
    acronym: 'NOx',
    assetPath: 'assets/images/nox/nox.png',
    description:
        'Toxic gases produced largely by burning fuel, especially in cars and gas stoves.',
    healthEffects:
        'Reacts to form smog and acid rain. Inhaling NOx reduces lung function and increases susceptibility to respiratory infections.',
    themeColor: Colors.redAccent,
  ),
  PollutantInfo(
    name: 'Carbon Dioxide',
    acronym: 'CO2',
    assetPath: 'assets/images/co2_high/co2_high_low.png',
    description:
        'A gas we exhale naturally, but which builds up quickly in crowded, poorly ventilated indoor spaces.',
    healthEffects:
        'High indoor levels cause "stuffy" air, leading to drowsiness, poor concentration, headaches, and decreased cognitive function.',
    themeColor: Colors.green,
  ),
];

class PollutantGuideScreen extends StatelessWidget {
  const PollutantGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Threat Guide')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: pollutantDatabase.length,
        itemBuilder: (context, index) {
          final pollutant = pollutantDatabase[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 4,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: pollutant.themeColor.withValues(alpha: 0.50),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Character Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: pollutant.themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      // We use the first frame of your animation sequence
                      child: Image.asset(
                        pollutant.assetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pollutant.name} (${pollutant.acronym})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: pollutant.themeColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pollutant.description,
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const Divider(height: 24),
                        const Text(
                          'Health Effects:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pollutant.healthEffects,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
