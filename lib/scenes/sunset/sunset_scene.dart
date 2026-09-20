import 'package:flutter/material.dart';

import '../../app/theme/lighting.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../components/controls.dart';
import '../../components/reveal.dart';
import '../../components/scene_layout.dart';
import '../../components/scene_ui.dart';
import '../../world/painters/character.dart';
import '../../world/painters/landscape.dart';
import '../../world/plate.dart';
import '../../world/plates.g.dart';
import '../../world/stage.dart';

/// Frame 12 — Final / Contact.
///
/// The world opens out at sunset. Contact lives inside the scene rather than
/// in a footer, per the PRD.
class SunsetScene extends StatelessWidget {
  const SunsetScene({
    super.key,
    required this.onNavigate,
    required this.onContact,
  });

  final void Function(String route) onNavigate;

  /// Opens an external destination — email, LinkedIn, GitHub, résumé.
  final void Function(String target) onContact;

  /// Contact buttons, traced off `assets/art/sunset.webp`. Same order as the
  /// painted row: Email, LinkedIn, GitHub, résumé.
  static const _contacts = <({Rect rect, String label, String target})>[
    (
      rect: Rect.fromLTRB(117, 422, 324, 491),
      label: 'Email',
      target: 'mailto:gyanupadhyay19@gmail.com',
    ),
    (rect: Rect.fromLTRB(352, 422, 565, 491), label: 'LinkedIn', target: 'linkedin'),
    (rect: Rect.fromLTRB(583, 422, 800, 491), label: 'GitHub', target: 'github'),
    (rect: Rect.fromLTRB(820, 422, 1046, 491), label: 'Resume', target: 'resume'),
  ];

  @override
  Widget build(BuildContext context) {
    // On a plate the painting carries the invitation and the buttons; the
    // scene contributes the targets over them.
    final plate = platesOn(context);
    return WorldStage(
      lighting: SceneLighting.sunset,
      ui: SceneUi(
        leading: Reveal(child: _Back(onTap: () => onNavigate('/map'))),
        // The light and the ambience, reachable from here rather than only
        // from the two screens that show a nav.
        extras: [
          At(right: T.s24, top: T.s24, child: AmbientToggles(composed: SceneLighting.sunset)),
        ],
        copy: plate ? const [] : [CopySlot(
          left: 90,
          top: 272,
          width: 920,
          child: RevealGroup(
            start: const Duration(milliseconds: 200),
            children: [
              HandwrittenAccent(
                text: 'Still curious?',
                style: Type.handTitle.copyWith(fontSize: 58),
                color: const Color(0xFF2E4A7A),
                rotation: -0.06,
              ),
              const SizedBox(height: T.s24),
              // The reference sets this line in script too, not sans.
              HandwrittenAccent(
                text: "Let's build something meaningful.",
                style: Type.handNote.copyWith(fontSize: 40),
                color: const Color(0xFF243A56),
                rotation: -0.06,
              ),
              const SizedBox(height: T.s40),
              IconActionRow(
                spacing: 24,
                actions: [
                  IconAction(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    onTap: () => onContact('mailto:gyanupadhyay19@gmail.com'),
                  ),
                  IconAction(
                    icon: Icons.business_center_outlined,
                    label: 'LinkedIn',
                    onTap: () => onContact('linkedin'),
                  ),
                  IconAction(
                    icon: Icons.code,
                    label: 'GitHub',
                    onTap: () => onContact('github'),
                  ),
                  IconAction(
                    icon: Icons.description_outlined,
                    label: 'Resume',
                    onTap: () => onContact('resume'),
                  ),
                ],
              ),
            ],
          ),
        )],
        accents: plate ? const [] : const [
          At(
            right: 78,
            top: 78,
            width: 250,
            child: Reveal(
              delay: Duration(milliseconds: 760),
              child: HandwrittenAccent(
                text: 'Same sky\nBigger dreams\nSee you soon.',
                style: Type.handNote,
                color: Color(0xFF3A2A22),
                rotation: -0.05,
                shadow: false,
                align: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
      children: plate
          ? [
              ScenePlate(
                art: plateSunset,
                lighting: SceneLighting.sunset,
                children: [
                  for (final contact in _contacts)
                    PlateHotspot(
                      rect: contact.rect,
                      label: contact.label,
                      onTap: () => onContact(contact.target),
                    ),
                ],
              ),
            ]
          : [
        SceneLayer(seed: 11, paint: [Landscape.sky, Landscape.sunDisc]),

        ParallaxLayer(
          depth: 0.08,
          child: SceneLayer(
            seed: 601,
            paint: [
              Landscape.clouds(seed: 601, band: 0.12, count: 5, scale: 0.7),
              Landscape.clouds(
                seed: 603,
                band: 0.26,
                count: 4,
                scale: 0.5,
                opacity: 0.8,
              ),
            ],
          ),
        ),

        ParallaxLayer(
          depth: 0.18,
          child: SceneLayer(
            seed: 7,
            repaintOnTime: false,
            paint: [
              Landscape.mountains(
                seed: 7,
                top: 0.30,
                bottom: 0.60,
                roughness: 5.0,
                distance: 0.52,
              ),
            ],
          ),
        ),

        ParallaxLayer(
          depth: 0.28,
          child: SceneLayer(
            seed: 605,
            repaintOnTime: false,
            paint: [
              Landscape.mountains(
                seed: 605,
                top: 0.40,
                bottom: 0.66,
                roughness: 7.0,
                distance: 0.34,
                snow: false,
                tint: const Color(0xFF6A5A78),
              ),
            ],
          ),
        ),

        ParallaxLayer(
          depth: 0.4,
          child: SceneLayer(
            seed: 607,
            repaintOnTime: false,
            paint: [
              Cityscape.skyline(
                seed: 607,
                baseline: 0.63,
                height: 0.12,
                distance: 0.42,
                count: 24,
              ),
            ],
          ),
        ),

        ParallaxLayer(
          depth: 0.5,
          child: SceneLayer(
            seed: 609,
            paint: [Landscape.lake(seed: 609, top: 0.60, bottom: 0.88)],
          ),
        ),

        ParallaxLayer(
          depth: 0.7,
          child: SceneLayer(
            seed: 611,
            repaintOnTime: false,
            paint: [
              Landscape.hills(
                seed: 611,
                top: 0.80,
                bottom: 1.08,
                distance: 0.05,
                amplitude: 0.34,
                treeCount: 30,
                treeScale: 0.65,
                color: const Color(0xFF3A4A38),
              ),
            ],
          ),
        ),

        ParallaxLayer(
          depth: 0.3,
          child: SceneLayer(
            seed: 613,
            paint: [Landscape.birds(seed: 613, band: 0.2)],
          ),
        ),

        ParallaxLayer(
          depth: 0.9,
          child: SceneLayer(seed: 615, paint: [_figureAndCat]),
        ),

        ParallaxLayer(
          depth: 1.0,
          child: SceneLayer(
            seed: 617,
            repaintOnTime: false,
            paint: [
              Landscape.foliageFrame(seed: 617, right: false, scale: 0.8),
            ],
          ),
        ),

        SceneLayer(seed: 91, repaintOnTime: false, paint: [Landscape.ambient]),
      ],

    );
  }

  static void _figureAndCat(Canvas canvas, Size size, ScenePaintContext ctx) {
    final base = Offset(size.width * 0.80, size.height * 1.0);
    // A grassy mound to sit on.
    canvas.drawOval(
      Rect.fromCenter(
        center: base.translate(0, size.height * 0.06),
        width: size.width * 0.3,
        height: size.height * 0.16,
      ),
      Paint()..color = const Color(0xFF32402F),
    );
    Character.paint(
      canvas,
      base,
      size.height * 0.67,
      Pose.seatedBack,
      CharacterPalette.sunset,
      ctx,
      backpack: false,
      breathe: ctx.time * 0.9,
    );
    Character.cat(
      canvas,
      base.translate(-size.width * 0.075, -6),
      100,
      ctx,
      facing: 1,
      tailPhase: ctx.time * 1.5,
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Hotspot(
      label: 'Back to the journey map',
      tooltip: 'Back to the map',
      onActivate: onTap,
      builder: (context, active) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: active ? 0.5 : 0.3),
          borderRadius: BorderRadius.circular(T.rPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, size: 14, color: Colors.white),
            const SizedBox(width: T.s6),
            Text('The map', style: Type.labelSm.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
