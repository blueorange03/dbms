document.addEventListener('DOMContentLoaded',()=>{
  document.querySelectorAll('input[name="start_time"]').forEach((input)=>{
    const d=new Date();d.setMinutes(d.getMinutes()-d.getTimezoneOffset());d.setMinutes(d.getMinutes()+30);
    input.min=d.toISOString().slice(0,16);
  });
  const hash=window.location.hash;
  if(hash==='#violations'){
    const tab=document.querySelector('[data-bs-target="#violations"]');
    if(tab) bootstrap.Tab.getOrCreateInstance(tab).show();
  }
});
