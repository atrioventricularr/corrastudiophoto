try { require('./corra-disk-preload.cjs'); } catch (error) {
  console.warn('[Corra] disk preload not loaded:', error.message);
}

try { require('./corra-hardware-preload.cjs'); } catch (error) {
  console.warn('[Corra] hardware preload not loaded:', error.message);
}
