const app = document.getElementById("app");

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
app.appendChild(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x0f1115);

const camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.set(0, 1.6, 3);

const ambient = new THREE.AmbientLight(0xffffff, 0.4);
scene.add(ambient);

const dirLight = new THREE.DirectionalLight(0xffffff, 0.8);
dirLight.position.set(5, 10, 7.5);
scene.add(dirLight);

const cubeGeo = new THREE.BoxGeometry(1, 1, 1);
const cubeMat = new THREE.MeshStandardMaterial({ color: 0x4f46e5 });
const cube = new THREE.Mesh(cubeGeo, cubeMat);
scene.add(cube);

const groundGeo = new THREE.PlaneGeometry(20, 20);
const groundMat = new THREE.MeshStandardMaterial({ color: 0x1f2937, roughness: 1.0, metalness: 0.0 });
const ground = new THREE.Mesh(groundGeo, groundMat);
ground.rotation.x = -Math.PI / 2;
scene.add(ground);

const clock = new THREE.Clock();

let yaw = 0;
let pitch = 0;
let moveForward = false;
let moveBackward = false;
let moveLeft = false;
let moveRight = false;

function updateCameraRotation(dx, dy) {
  const sensitivity = 0.0025;
  yaw -= dx * sensitivity;
  pitch -= dy * sensitivity;
  const maxPitch = Math.PI / 2 - 0.05;
  pitch = Math.max(-maxPitch, Math.min(maxPitch, pitch));
  const euler = new THREE.Euler(pitch, yaw, 0, "YXZ");
  camera.quaternion.setFromEuler(euler);
}

document.addEventListener("click", () => {
  if (document.pointerLockElement !== renderer.domElement) {
    renderer.domElement.requestPointerLock();
  }
});

document.addEventListener("pointerlockchange", () => {
  if (document.pointerLockElement === renderer.domElement) {
    document.addEventListener("mousemove", onMouseMove);
  } else {
    document.removeEventListener("mousemove", onMouseMove);
  }
});

function onMouseMove(e) {
  updateCameraRotation(e.movementX, e.movementY);
}

document.addEventListener("keydown", (e) => {
  switch (e.code) {
    case "KeyW": moveForward = true; break;
    case "KeyS": moveBackward = true; break;
    case "KeyA": moveLeft = true; break;
    case "KeyD": moveRight = true; break;
    case "KeyR": resetCamera(); break;
  }
});

document.addEventListener("keyup", (e) => {
  switch (e.code) {
    case "KeyW": moveForward = false; break;
    case "KeyS": moveBackward = false; break;
    case "KeyA": moveLeft = false; break;
    case "KeyD": moveRight = false; break;
  }
});

function resetCamera() {
  yaw = 0;
  pitch = 0;
  camera.position.set(0, 1.6, 3);
  camera.quaternion.set(0, 0, 0, 1);
}

function animate() {
  requestAnimationFrame(animate);
  const dt = Math.min(clock.getDelta(), 0.05);
  const speed = 3.0;
  const forward = new THREE.Vector3();
  camera.getWorldDirection(forward);
  forward.y = 0;
  forward.normalize();
  const right = new THREE.Vector3().crossVectors(new THREE.Vector3(0,1,0), forward).normalize();
  if (moveForward) camera.position.addScaledVector(forward, speed * dt);
  if (moveBackward) camera.position.addScaledVector(forward, -speed * dt);
  if (moveLeft) camera.position.addScaledVector(right, -speed * dt);
  if (moveRight) camera.position.addScaledVector(right, speed * dt);
  cube.rotation.y += dt * 0.6;
  cube.rotation.x += dt * 0.25;
  renderer.render(scene, camera);
}

animate();

window.addEventListener("resize", () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});