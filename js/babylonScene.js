// Adapted from aWeirdo's simple server tutorial:
// https://github.com/aWeirdo

var canvas = document.getElementById('renderCanvas');

var createScene = function () {
  var scene = new BABYLON.Scene(engine);

  scene.clearColor = new BABYLON.Color3(0.02, 0.01, 0.02);
  scene.ambientColor = new BABYLON.Color3(0.02, 0.01, 0.02);
  scene.gravity = new BABYLON.Vector3(0, -2.4525, 0);
  scene.collisionsEnabled = true;

  var light = new BABYLON.HemisphericLight(
    'light1',
    new BABYLON.Vector3(0, 1, 0),
    scene
  );
  light.intensity = 0.15;

  var camera = new BABYLON.DeviceOrientationCamera(
    'camera1',
    new BABYLON.Vector3(0, 0, 0),
    scene
  );
  camera.setTarget(new BABYLON.Vector3(0, 0, 0));
  camera.ellipsoid = new BABYLON.Vector3(1.6, 2.4, 1.6);
  camera.applyGravity = true;
  camera.checkCollisions = true;
  camera.attachControl(canvas, true);
  camera.inputs.addTouch()
  canvas.focus()

  BABYLON.Effect.ShadersStore["customVertexShader"] = "precision highp float;\r\n" +

    "// Attributes\r\n" +
    "attribute vec3 position;\r\n" +
    "attribute vec3 normal;\r\n" +
    "attribute vec2 uv;\r\n" +

    "// Uniforms\r\n" +
    "uniform mat4 worldViewProjection;\r\n" +

    "// Varying\r\n" +
    "varying vec4 vPosition;\r\n" +
    "varying vec3 vNormal;\r\n" +

    "void main() {\r\n" +

    "    vec4 p =  vec4( position, 1. );\r\n" +

    "    vPosition = p;\r\n" +
    "    vNormal = normal;\r\n" +

    "    gl_Position = worldViewProjection * p;\r\n" +

    "}\r\n";

  BABYLON.Effect.ShadersStore["customFragmentShader"] = "precision highp float;\r\n" +

    "uniform mat4 worldView;\r\n" +

    "varying vec4 vPosition;\r\n" +
    "varying vec3 vNormal;\r\n" +

    "uniform sampler2D textureSampler;\r\n" +
    "uniform sampler2D refSampler;\r\n" +
    "uniform vec3 iResolution;\r\n" +

    "const float tau = 6.28318530717958647692;\r\n" +

    "// Gamma correction\r\n" +
    "#define GAMMA (2.2)\r\n" +

    "vec3 ToLinear( in vec3 col )\r\n" +
    "{\r\n" +
    "	// simulate a monitor, converting colour values into light values\r\n" +
    "	return pow( col, vec3(GAMMA) );\r\n" +
    "}\r\n" +

    "vec3 ToGamma( in vec3 col )\r\n" +
    "{\r\n" +
    "	// convert back into colour values, so the correct light will come out of the monitor\r\n" +
    "	return pow( col, vec3(1.0/GAMMA) );\r\n" +
    "}\r\n" +

    "vec4 Noise( in ivec2 x )\r\n" +
    "{\r\n" +
    "	return texture2D( refSampler, (vec2(x)+0.5)/256.0, -100.0 );\r\n" +
    "}\r\n" +

    "vec4 Rand( in int x )\r\n" +
    "{\r\n" +
    "	vec2 uv;\r\n" +
    "	uv.x = (float(x)+0.5)/256.0;\r\n" +
    "	uv.y = (floor(uv.x)+0.5)/256.0;\r\n" +
    "	return texture2D( refSampler, uv, -100.0 );\r\n" +
    "}\r\n" +

    "uniform float time;\r\n" +

    "void main(void) {\r\n" +

    "    vec3 ray;\r\n" +
    "	ray.xy = .2*(vPosition.xy-vec2(.5));\r\n" +
    "	ray.z = 1.;\r\n" +
    "   // setting a negative offset will make starfield travel away from viewer\r\n" +
    "	//float offset = time*.5;	\r\n" +
    " float offset = time*0.005;\r\n" +
    "	//float speed2 = (cos(offset)+1.0)*2.0;\r\n" +
    " float speed2 = 0.01;\r\n" +
    "	float speed = speed2+.1;\r\n" +
    "	//offset += sin(offset)*.96;\r\n" +
    "	offset *= 2.0;\r\n" +
    "	\r\n" +
    "	\r\n" +
    "	vec3 col = vec3(0.);\r\n" +
    "	\r\n" +
    "	vec3 stp = ray/max(abs(ray.x),abs(ray.y));\r\n" +
    "	\r\n" +
    "	vec3 pos = 2.0*stp+.5;\r\n" +
    "	for ( int i=0; i < 16; i++ )\r\n" +
    "	{\r\n" +
    "		float z = Noise(ivec2(pos.xy)).x;\r\n" +
    "		z = fract(z-offset);\r\n" +
    "		float d = 50.0*z-pos.z;\r\n" +
    "		float w = pow(max(0.0,1.0-8.0*length(fract(pos.xy)-.5)),2.0);\r\n" +
    "		vec3 c = max(vec3(0),vec3(1.0-abs(d+speed2*.5)/speed,1.0-abs(d)/speed,1.0-abs(d-speed2*.5)/speed));\r\n" +
    "		col += 1.5*(1.0-z)*c*w;\r\n" +
    "		pos += stp;\r\n" +
    "	}\r\n" +
    "	\r\n" +
    "	gl_FragColor = vec4(ToGamma(col),1.);\r\n" +

    "}\r\n";

  var shaderMaterial = new BABYLON.ShaderMaterial("shader", scene, {
    vertex: "custom",
    fragment: "custom",
  },
    {
      attributes: ["position", "normal", "uv"],
      uniforms: ["world", "worldView", "worldViewProjection", "view", "projection"]
    });

  var refTexture = new BABYLON.Texture("./textures/noise_image.png", scene);

  shaderMaterial.setTexture("refSampler", refTexture);
  shaderMaterial.setFloat("time", 0);
  shaderMaterial.setVector3("cameraPosition", BABYLON.Vector3);
  shaderMaterial.backFaceCulling = false;

  var mesh = BABYLON.Mesh.CreateIcoSphere("mesh", {
    radius: 500.0,
    flat: true,
    subdivisions: 16,
    updatable: true
  })

  mesh.material = shaderMaterial;
  mesh.backFaceCulling = false;

  var time = 0;

  BABYLON.SceneLoader.ImportMesh('', './assets/', 'scene.babylon', scene, function (
    newMeshes
  ) {
    var mesh = newMeshes[0];
    mesh.position.copyFromFloats(0, 0, 0);
    mesh.scaling.copyFromFloats(4, 4, 4);

    newMeshes.forEach(m => {
      if (m.id === 'ShipParentObj' || m.id === 'NavigationMesh') {
        m.isVisible = false;

        if (m.id === 'NavigationMesh') {
          m.checkCollisions = true;
        }
      }
    });

    scene.materials[5].sideOrientation =
      BABYLON.Material.CounterClockWiseSideOrientation
    scene.materials[6].sideOrientation =
      BABYLON.Material.CounterClockWiseSideOrientation

    var pbr = new BABYLON.PBRSpecularGlossinessMaterial('pbr', scene)

    pbr.diffuseColor = new BABYLON.Color3(0.05, 0, 0.1)
    pbr.specularColor = new BABYLON.Color3(1.0, 0, 1)
    pbr.glossiness = 1
    pbr.alpha = 0.95

    console.log(mesh);
  });

  scene.registerBeforeRender(function () {
    shaderMaterial.setFloat('time', time);
    time += 0.03125;

    shaderMaterial.setVector3('cameraPosition', scene.activeCamera.position);
  });

  return scene;
};

// Configure the engine
var engine = new BABYLON.Engine(canvas, true, {
  preserveDrawingBuffer: true,
  stencil: true
});

// Create the scene
var scene = createScene();

// Render the scene
engine.runRenderLoop(function () {
  if (scene) {
    scene.render();
  }
});

// Resize
window.addEventListener('resize', function () {
  engine.resize();
});