function VoxelGrid(container_id, grid_dimensions, voxel_values)
{
  console.log("drawing voxel grid " + container_id);

  var width = 640;
  var height = 480;
  var aspect_ratio = width / height;

  var max_x = grid_dimensions[0];
  var max_y = grid_dimensions[1];
  var max_z = grid_dimensions[2];
  var max_dim = Math.max(max_x, max_y, max_z);

  var container, camera, scene, renderer, controls;
  var geometry, box, material;

  init();
  animate();

  function init() {
      container = document.getElementById(container_id);

      camera = new THREE.PerspectiveCamera(75, aspect_ratio, 1, max_dim*100);
      camera.position.set(max_x/2, max_y/2, max_z*3);

      controls = new THREE.TrackballControls( camera );
      controls.enabled = false;

      scene = new THREE.Scene();

      // coordinate axes
      function v(x,y,z){
        return new THREE.Vertex(new THREE.Vector3(x,y,z));
      }

      var lineGeo = new THREE.Geometry();
      lineGeo.vertices.push(
        v(0, 0, 0), v(max_dim, 0, 0),
        v(0, 0, 0), v(0, max_dim, 0),
        v(0, 0, 0), v(0, 0, max_dim)
      );
      var lineMat = new THREE.LineBasicMaterial({
        color: 0xffffff, lineWidth: 2});
      var line = new THREE.Line(lineGeo, lineMat);
      line.type = THREE.Lines;
      scene.add(line);

      geometry = new THREE.Geometry();
      box = new THREE.BoxGeometry(1, 1, 1);
      material = new THREE.MeshPhongMaterial({
        specular: 0xffffff,
        color: 0xcccccc,
        emissive: 0x999999
      });

      var ambientLight = new THREE.AmbientLight(0x222222);
      scene.add(ambientLight);

      var directionalLight = new THREE.DirectionalLight(0xffffff);
      directionalLight.position.set(0, 2*max_y, 0);
      scene.add(directionalLight);

      for (var x = 0; x < max_x; x+=1) {
        for (var y = 0; y < max_y; y+=1) {
          for (var z = 0; z < max_z; z+=1) {
            var i = ((((x * max_x) + y) * max_y) + z);
            if (voxel_values[i] == 1){
              var position = new THREE.Vector3( x,y,z );
              var cube = new THREE.Mesh( box );
              cube.position.copy( position );
              THREE.GeometryUtils.merge( geometry, cube );
            }
          }
        }
      }

      var drawnObject = new THREE.Mesh( geometry, material );
      scene.add( drawnObject );

      renderer = new THREE.WebGLRenderer();
      renderer.setClearColor(0x000000, 1);
      renderer.setSize(width, height);

      container.appendChild(renderer.domElement);

      window.addEventListener('mousedown', toggle_controls, false);
  }

  function toggle_controls(e) {
    controls.enabled = (e.target === renderer.domElement);
  }

  function animate() {
      requestAnimationFrame(animate);
      controls.update();
      renderer.render(scene, camera);
  }
}
