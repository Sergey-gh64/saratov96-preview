const CACHE='s96-runtime-v4';
const CORE=['./','./manifest.webmanifest','./icon-180.png','./icon-512.png'];
self.addEventListener('install',event=>{
  self.skipWaiting();
  event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(CORE)).catch(()=>{}));
});
self.addEventListener('activate',event=>{
  event.waitUntil((async()=>{
    const keys=await caches.keys();
    await Promise.all(keys.filter(key=>key!==CACHE).map(key=>caches.delete(key)));
    await self.clients.claim();
  })());
});
self.addEventListener('fetch',event=>{
  if(event.request.method!=='GET') return;
  event.respondWith((async()=>{
    try{
      const fresh=await fetch(event.request,{cache:'no-store'});
      if(fresh && fresh.ok){
        const cache=await caches.open(CACHE);
        cache.put(event.request,fresh.clone());
      }
      return fresh;
    }catch(_){
      const cache=await caches.open(CACHE);
      const cached=await cache.match(event.request);
      if(cached) return cached;
      if(event.request.mode==='navigate') return (await cache.match('./')) || Response.error();
      return Response.error();
    }
  })());
});
