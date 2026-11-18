import 'package:flutter/material.dart';
import '../models/prompt_template.dart';

const promptTemplates = [
  PromptTemplate(
    title: 'Lantern street',
    tag: 'LIGHT & REFLECTIONS',
    icon: Icons.nightlight_round,
    ratio: 'portrait',
    prompt:
        'A rain-soaked Kyoto side street at blue hour, paper lanterns reflected in the pavement, a lone cyclist passing, cinematic photography, intricate architecture, warm amber light, realistic details.',
  ),
  PromptTemplate(
    title: 'Cobalt teapot',
    tag: 'PRODUCT TEXTURE',
    icon: Icons.coffee_rounded,
    ratio: 'square',
    prompt:
        'A handcrafted ceramic teapot with deep cobalt glaze on natural linen, soft morning window light, editorial product photography, crisp glaze texture, gentle shadows, uncluttered warm studio.',
  ),
  PromptTemplate(
    title: 'Rooftop glasshouse',
    tag: 'ATMOSPHERE',
    icon: Icons.park_rounded,
    ratio: 'portrait',
    prompt:
        'A tiny greenhouse on a rooftop at night, glowing plants behind rain-streaked glass, distant city lights, cinematic illustration, rich botanical detail, atmospheric blue and amber lighting.',
  ),
  PromptTemplate(
    title: 'The old knight',
    tag: 'MATERIAL & DETAIL',
    icon: Icons.shield_moon_rounded,
    ratio: 'landscape',
    prompt:
        'A weathered medieval knight with a broad sword standing on a windswept ridge, dramatic clouds, engraved steel, grounded fantasy concept art, precise armor details, cinematic natural light.',
  ),
  PromptTemplate(
    title: 'Coral reef observatory',
    tag: 'UNDERWATER WORLD',
    icon: Icons.scuba_diving_rounded,
    ratio: 'landscape',
    prompt:
        'A glass underwater research station nestled in a thriving coral reef, tiny divers observing a manta ray beyond the window, sunbeams scattering through turquoise water, bioluminescent plankton, detailed environmental concept art, rich natural colors.',
  ),
  PromptTemplate(
    title: 'Paper moon bakery',
    tag: 'WHIMSICAL STILL LIFE',
    icon: Icons.bakery_dining_rounded,
    ratio: 'square',
    prompt:
        'A tiny midnight bakery built inside a crescent moon, a sleepy fox baker arranging star-shaped pastries, warm oven glow against a deep indigo sky, delicate cut-paper illustration, tactile layered paper textures, charming storybook composition.',
  ),
];
