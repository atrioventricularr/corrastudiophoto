import React from 'react';
import { useLayouts } from '../layouts';

export function CameraGuideOverlay() {
  const {
    activeLayout,
    guideSettings,
  } = useLayouts();

  const opacity = guideSettings.guideOpacity;

  if (!guideSettings.showGrid && !guideSettings.showSlotGuide) {
    return null;
  }

  return (
    <div
      className="pointer-events-none absolute inset-0 z-20 overflow-hidden rounded-[inherit]"
      style={{
        opacity,
      }}
    >
      {guideSettings.showGrid && (
        <div className="absolute inset-0 bg-[linear-gradient(to_right,rgba(255,255,255,0.35)_1px,transparent_1px),linear-gradient(to_bottom,rgba(255,255,255,0.35)_1px,transparent_1px)] bg-[size:10%_10%]" />
      )}

      {guideSettings.showSlotGuide &&
        activeLayout.slots
          .filter((slot) => slot.showGuide)
          .map((slot) => (
            <div
              key={slot.id}
              className="absolute flex items-center justify-center border-2 border-dashed border-white bg-black/15 text-center shadow-[0_0_0_1px_rgba(0,0,0,0.25)]"
              style={{
                left: `${slot.xPercent}%`,
                top: `${slot.yPercent}%`,
                width: `${slot.widthPercent}%`,
                height: `${slot.heightPercent}%`,
                borderRadius:
                  slot.shape === 'circle'
                    ? '9999px'
                    : `${slot.borderRadiusPercent}%`,
                transform: `rotate(${slot.rotationDeg}deg)`,
              }}
            >
              <div className="rounded-full bg-black/55 px-3 py-1">
                <p className="text-[10px] font-black uppercase tracking-wider text-white">
                  {slot.guideLabel || slot.name}
                </p>
                <p className="mt-0.5 font-mono text-[9px] font-bold text-white/75">
                  #{slot.captureOrder}
                </p>
              </div>
            </div>
          ))}
    </div>
  );
}
