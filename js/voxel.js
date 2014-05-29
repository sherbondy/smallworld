function VoxelGrid(container_id, grid_dimensions, voxel_values)
{
  console.log("drawing voxel grid " + container_id);

  var width = 640;
  var height = 480;

  var container, camera, scene, renderer;
  var geometry, material, mesh;

  init();
  animate();

  function init() {
      container = document.getElementById(container_id);

      camera = new THREE.PerspectiveCamera(75, width / height, 1, 10000);
      camera.position.z = 1000;

      scene = new THREE.Scene();

      geometry = new THREE.BoxGeometry(200, 200, 200);
      material = new THREE.MeshBasicMaterial({
          color: 0xff0000,
          wireframe: true
      });

      mesh = new THREE.Mesh(geometry, material);
      scene.add(mesh);

      renderer = new THREE.CanvasRenderer();
      renderer.setSize(width, height);

      container.appendChild(renderer.domElement);

  }

  function animate() {

      // note: three.js includes requestAnimationFrame shim
      requestAnimationFrame(animate);

      mesh.rotation.x += 0.01;
      mesh.rotation.y += 0.02;

      renderer.render(scene, camera);

  }
}
