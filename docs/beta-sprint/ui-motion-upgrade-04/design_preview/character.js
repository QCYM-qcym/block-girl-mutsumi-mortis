// Throwaway menu composition. Presentation-only transforms; no Runtime or gameplay actions.
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

const root=document.getElementById('game'),stage=document.getElementById('character-stage'),state=document.getElementById('render-state');
const caption=document.getElementById('motion-caption');
const source='../../../../production/art_3d/';
const assets={surface:'BG_CH_WAKABA_CUBE_001',inner:'BG_CH_MORTIS_CUBE_001'};
const palettes={surface:{background:0xb7c8c1,floor:0xb7c8c1,key:0xfff2dc,hemi:0xe7f2e9,ground:0x617b79},inner:{background:0x28364a,floor:0x28364a,key:0xd5d9ff,hemi:0xa5b9dc,ground:0x30334c}};
const scene=new THREE.Scene();scene.background=new THREE.Color(palettes.surface.background);
const camera=new THREE.OrthographicCamera(-2,2,1,-1,.1,50);
const target=new THREE.Vector3(-.55,.43,0);camera.position.set(target.x+2.1,target.y+1.7,5.6);camera.lookAt(target);
let renderer;
try{renderer=new THREE.WebGLRenderer({antialias:true,alpha:false});}
catch(error){state.dataset.status='renderer_failed';document.getElementById('load-status').textContent='当前预览环境无法启用 3D 显示';throw error;}
renderer.setPixelRatio(Math.min(devicePixelRatio,2));renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.0;
renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFShadowMap;stage.append(renderer.domElement);
const hemi=new THREE.HemisphereLight(0xe7f2e9,0x617b79,1.5);scene.add(hemi);
const key=new THREE.DirectionalLight(0xfff2dc,2.4);key.position.set(-3,5,5);key.castShadow=true;key.shadow.mapSize.set(2048,2048);Object.assign(key.shadow.camera,{left:-3,right:3,top:3,bottom:-3,near:.1,far:18});key.shadow.radius=4;key.shadow.bias=-.0003;key.shadow.normalBias=.015;key.shadow.blurSamples=12;scene.add(key);
const fill=new THREE.DirectionalLight(0xc9e5e5,.5);fill.position.set(3,1,-2);scene.add(fill);
const floor=new THREE.Mesh(new THREE.PlaneGeometry(80,80),new THREE.MeshStandardMaterial({color:0xb7c8c1,roughness:1,metalness:0}));floor.rotation.x=-Math.PI/2;floor.position.y=-.002;floor.receiveShadow=true;scene.add(floor);
const actor=new THREE.Group();scene.add(actor);
const models={};let reduced=root.classList.contains('reduced'),osReduced=matchMedia('(prefers-reduced-motion: reduce)').matches,world=root.dataset.world,action=null,activeSeconds=0,lastTime=null,frame=0,raf=0;
function resize(){const {width,height}=stage.getBoundingClientRect();if(!width||!height)return;const span=height>width?2.1:(width<=1050?1.95:1.70),aspect=width/height;camera.left=-span*aspect/2;camera.right=span*aspect/2;camera.top=span/2;camera.bottom=-span/2;camera.updateProjectionMatrix();renderer.setSize(width,height,false);}
new ResizeObserver(resize).observe(stage);resize();
const loader=new GLTFLoader();
Promise.all(Object.entries(assets).map(async([name,id])=>{
 const gltf=await loader.loadAsync(source+id+'/export/'+id+'.glb');
 const model=gltf.scene;model.traverse(node=>{if(node.isMesh){node.castShadow=true;node.receiveShadow=false;}});
 const box=new THREE.Box3().setFromObject(model);model.position.set(-(box.min.x+box.max.x)/2,-box.min.y,-(box.min.z+box.max.z)/2);
 model.userData.halfWidth=(box.max.x-box.min.x)/2;model.userData.halfDepth=(box.max.z-box.min.z)/2;
 model.visible=name===world;models[name]=model;actor.add(model);
})).then(()=>{root.dataset.loaded='true';state.dataset.status='ready';state.dataset.models=Object.keys(models).join(',');setWorld(root.dataset.world);}).catch(error=>{state.dataset.status='model_failed';document.getElementById('load-status').textContent='角色加载失败，请检查本地预览服务';console.error(error);});
function updateReduced(){const stopped=reduced||osReduced;if(stopped){action=null;state.dataset.action='idle';}state.dataset.reduced=String(stopped);document.querySelectorAll('[data-action]').forEach(button=>button.disabled=stopped);caption.textContent=stopped?'减少动态 · 静态展示':'角色动态展示';}
function setWorld(value){world=value;Object.entries(models).forEach(([name,model])=>model.visible=name===world);state.dataset.world=world;action=null;state.dataset.action='idle';}
window.addEventListener('showcase-world',event=>setWorld(event.detail.world));
window.addEventListener('showcase-options',event=>{reduced=event.detail.reduced;updateReduced();});
matchMedia('(prefers-reduced-motion: reduce)').addEventListener('change',event=>{osReduced=event.matches;updateReduced();});
window.addEventListener('showcase-action',event=>{if(reduced||osReduced||!models[world])return;action={kind:event.detail.action,start:activeSeconds};state.dataset.action=action.kind;});
function tick(time){
 raf=0;if(document.hidden){lastTime=null;return;}
 const dt=lastTime===null?0:Math.min((time-lastTime)/1000,.05);lastTime=time;activeSeconds+=dt;
 const still=reduced||osReduced;
 let yaw=still?0:Math.sin(activeSeconds*.48)*.065,lean=still?0:Math.sin(activeSeconds*.31)*.009;
 if(action){const t=(activeSeconds-action.start)/2.1;if(t>=1){action=null;state.dataset.action='idle';}else{const bell=Math.sin(Math.PI*t)**2;if(action.kind==='turn')yaw+=bell*.24;else lean+=bell*.065;}}
 actor.rotation.set(0,yaw,lean);
 // Lift only enough to preserve the lowest support edge under a whole-model lean.
 actor.position.y=(models[world]?.userData.halfWidth||.5)*Math.abs(Math.sin(lean));
 const palette=palettes[world],blend=still?1:Math.min(1,dt*7);scene.background.lerp(new THREE.Color(palette.background),blend);floor.material.color.lerp(new THREE.Color(palette.floor),blend);key.color.lerp(new THREE.Color(palette.key),blend);hemi.color.lerp(new THREE.Color(palette.hemi),blend);hemi.groundColor.lerp(new THREE.Color(palette.ground),blend);
 renderer.render(scene,camera);frame++;
 if(frame%8===0){state.dataset.frame=String(frame);state.dataset.yaw=yaw.toFixed(5);state.dataset.lean=lean.toFixed(5);state.dataset.contactLift=actor.position.y.toFixed(5);state.dataset.visible=String(!document.hidden);}
 raf=requestAnimationFrame(tick);
}
document.addEventListener('visibilitychange',()=>{lastTime=null;state.dataset.visible=String(!document.hidden);if(document.hidden){if(raf)cancelAnimationFrame(raf);raf=0;}else if(!raf)raf=requestAnimationFrame(tick);});
window.addEventListener('pagehide',()=>{if(raf)cancelAnimationFrame(raf);raf=0;lastTime=null;});
window.addEventListener('pageshow',event=>{state.dataset.pageshowPersisted=String(event.persisted);if(!raf&&!document.hidden){lastTime=null;raf=requestAnimationFrame(tick);}});
updateReduced();raf=requestAnimationFrame(tick);
