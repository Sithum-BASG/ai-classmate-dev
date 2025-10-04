export function isoNow(): string {
  return new Date().toISOString();
}

export function timesOverlap(
  startA: string,
  endA: string,
  startB: string,
  endB: string
): boolean {
  // HH:mm:ss strings -> minutes since midnight
  const toMin = (t: string) => {
    const [h, m, s] = t.split(':').map((x) => parseInt(x, 10));
    return h * 60 + m + Math.floor((s || 0) / 60);
  };
  const a1 = toMin(startA);
  const a2 = toMin(endA);
  const b1 = toMin(startB);
  const b2 = toMin(endB);
  return a1 < b2 && b1 < a2;
}

export function timesOverlapDate(
  startA: Date,
  endA: Date,
  startB: Date,
  endB: Date
): boolean {
  const toMin = (d: Date) => d.getHours() * 60 + d.getMinutes();
  const a1 = toMin(startA);
  const a2 = toMin(endA);
  const b1 = toMin(startB);
  const b2 = toMin(endB);
  return a1 < b2 && b1 < a2;
}

export function addDays(date: Date, days: number): Date {
  const d = new Date(date);
  d.setDate(d.getDate() + days);
  return d;
}


