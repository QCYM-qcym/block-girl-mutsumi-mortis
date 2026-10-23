"""Write an isolated, geometry-free Blender reference material library.

Run with Blender --background --factory-startup --python THIS_FILE --
--output ABSOLUTE/FloatingCube_A2.blend --shader ABSOLUTE/roof_coarse_a2.gdshader.
The caller owns process/profile isolation. This script never imports, constructs,
exports, or substitutes model geometry and never operates another Blender process.
"""

import argparse
import datetime as dt
import hashlib
import json
import math
from pathlib import Path
import subprocess
import sys


REPO = Path(__file__).resolve().parents[4]
A1_RELATIVE = "tests/beta_sprint/spatial_art/polish_03/roof_coarse.gdshader"
FROZEN_SOURCES = {
    A1_RELATIVE: "d86a48af1c7947ba629d6dca5959b40c8dd16e3aaf05034c728d7d344762d627",
    "experiments/game_feel_01/host/core_lab.gd": "b5d7d6c19a65dd167b9ee4a32c1074912c547482e9ac11370dcfc6fd336cdf0b",
    "experiments/spatial_puzzle_batch_01/host/spatial_lab.gd": "7906c6917f861df420abf2b260ed5c849d5a89418eb4caa4f353ea20097304b7",
    "experiments/spatial_puzzle_batch_01/maps/authoring/world_shift_gate_lab/surface.tscn": "e8fbb0810ed282c824b664f402b145388fb881c70f5f26296e7c0600de7d5785",
}
PALETTE = ((0.23, 0.28, 0.33), (0.48, 0.53, 0.55))
MATERIAL_NAMES = {"A1": "FloatingCube_A1_REFERENCE", "A2": "FloatingCube_A2_REFERENCE"}
REFERENCE_PARAMETERS = {
    "A1": {"roughness": 0.94, "metallic": 0.0, "specular_ior_level": 0.5, "albedo_multiplier": 1.0},
    "A2": {"roughness": 0.90, "metallic": 0.0, "specular_ior_level": 0.15, "albedo_multiplier": 1.06,
           "bump_strength": 0.10, "bump_distance_blender_units": 0.005, "micro_noise_scale": 32.0},
}
README = """FloatingCube A2 / B2 — MATERIAL_LIBRARY_ONLY

NOT_ORIGINAL_SOURCE_BLEND
NOT_A_BLENDER_MODEL_PREVIEW

This .blend contains editable reference materials and source texts only.
It contains ZERO objects and ZERO meshes. No geometry was created or imported.
It is not an original model source, a reconstructed roof, or a Blender render
of the actual Godot level. No Blender visual score or screenshot is provided.

The actual target is the procedural Godot BoxMesh assigned by
experiments/game_feel_01/host/core_lab.gd. The authoring source is
experiments/spatial_puzzle_batch_01/maps/authoring/world_shift_gate_lab/surface.tscn:
roof UUID 06c03444-c53b-49bb-6834-458cf9eb007a, position (1, 6, 0),
identity basis, unit bounds, Surface only, all six faces nonwalkable.
spatial_lab.gd labels this mesh NON_WALKABLE_OCCLUDER.
No trusted original .blend has been established for this target.
The unrelated combined_D01 design greybox is not used or substituted.

A1_AUTHORITY.gdshader and A2_AUTHORITY.gdshader are the actual read-only Godot
shader sources (line endings normalized to LF for Blender Text storage).
SOURCE_IDENTITY.json contains their raw-file hashes and source identities.
The Godot shaders, not the Blender node graph, govern Godot preview behavior.

The Blender graph reproduces the A1 broad color wave as a reference, using
Object coordinates and object-space Texture Coordinate normals. A2 multiplies
both original palette endpoints uniformly by 1.06, retaining channel ratios,
and adds only micro Noise -> Bump to this Blender reference graph.
No geometry, displacement output, displacement modifier, emission, alpha
effect, light, camera, or world-lighting adjustment is authored.

Blender REFERENCE PARAMETERS (not a one-to-one Godot parameter mapping):
A1: Roughness 0.94; Metallic 0; Specular IOR Level 0.50.
A2: Roughness 0.90; Metallic 0; Specular IOR Level 0.15;
    Bump Strength 0.10; Bump Distance 0.005 Blender units;
    3D Noise Scale 32. Scene unit scale is 1.0, unit system NONE.
The A1 IOR-level value is a Blender reference setting, not a claim about an
explicit A1 Godot SPECULAR value. The Godot A1 shader does not set SPECULAR.
Bump-distance units and renderer lighting/color behavior are not equivalent
between the engines. These nodes do not establish Godot pixel equivalence.
Materials have fake users and remain editable without objects.

The saved file is reopened in the same background process. The adjacent
BLENDER_REOPEN.json records the actual reopened node parameters, source and
executable hashes, Blender version, and zero-object/zero-mesh verification.
"""


def sha256(path):
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def text_sha256(value):
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def normalized_text(path):
    return Path(path).read_bytes().decode("utf-8").replace("\r\n", "\n").replace("\r", "\n")


def preflight():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--shader", type=Path, required=True)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    require(args.output.is_absolute() and args.shader.is_absolute(), "Absolute paths required")
    output, shader = args.output.resolve(), args.shader.resolve()
    require(output.name == "FloatingCube_A2.blend", "Expected FloatingCube_A2.blend")
    require(not output.is_relative_to(REPO), "Output must be outside the source worktree")
    require(output.parent.is_dir(), "Caller must provide the isolated output directory")
    receipt = output.with_name("BLENDER_REOPEN.json")
    for candidate in (output, receipt, Path(str(output) + "1"), Path(str(output) + "2")):
        require(not candidate.exists(), "Refusing to overwrite: " + str(candidate))
    require(shader == Path(__file__).resolve().with_name("roof_coarse_a2.gdshader"),
            "A2 authority must be the shader beside this script")
    require(shader.is_file(), "Missing A2 authority shader")
    source_files = []
    for relative, expected in FROZEN_SOURCES.items():
        path = REPO / relative
        actual = sha256(path)
        require(actual == expected, "Frozen source identity changed: " + relative)
        source_files.append({"path": str(path), "sha256": actual, "repository_path": relative})
    for path in (shader, Path(__file__).resolve()):
        source_files.append({"path": str(path), "sha256": sha256(path),
                             "repository_path": path.relative_to(REPO).as_posix()})
    shader_texts = {"A1_AUTHORITY.gdshader": normalized_text(REPO / A1_RELATIVE),
                    "A2_AUTHORITY.gdshader": normalized_text(shader)}
    identity = {
        "artifact_class": "MATERIAL_LIBRARY_ONLY",
        "source_blend_status": "NOT_ORIGINAL_SOURCE_BLEND",
        "preview_status": "NOT_A_BLENDER_MODEL_PREVIEW",
        "source_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO, text=True).strip(),
        "source_branch": subprocess.check_output(["git", "branch", "--show-current"], cwd=REPO, text=True).strip(),
        "files": source_files,
        "target": {"cube_id": "roof", "authoring_id": "06c03444-c53b-49bb-6834-458cf9eb007a",
                   "godot_position": [1, 6, 0], "mesh": "runtime procedural Godot BoxMesh",
                   "role": "NON_WALKABLE_OCCLUDER", "layer": "SURFACE", "walkable_faces": 0},
        "blender_parameters_are_reference_only": True,
        "godot_pixel_equivalence": "NOT_CLAIMED",
        "blender_rendering": "NOT_RUN",
        "blender_reference_parameters": REFERENCE_PARAMETERS,
        "text_line_endings": "LF; raw-file SHA256 retained separately",
        "authority_text_sha256": {name: text_sha256(value) for name, value in shader_texts.items()},
    }
    return output, receipt, identity, shader_texts


def math_node(tree, name, operation, *values):
    node = tree.nodes.new("ShaderNodeMath")
    node.name = name
    node.label = name
    node.operation = operation
    for index, value in enumerate(values):
        if isinstance(value, (int, float)):
            node.inputs[index].default_value = value
        else:
            tree.links.new(value, node.inputs[index])
    return node.outputs[0]


def broadwave(tree, coordinates):
    position = tree.nodes.new("ShaderNodeSeparateXYZ")
    position.name = "Object_position_XYZ"
    normal = tree.nodes.new("ShaderNodeSeparateXYZ")
    normal.name = "Object_normal_XYZ"
    tree.links.new(coordinates.outputs["Object"], position.inputs[0])
    tree.links.new(coordinates.outputs["Normal"], normal.inputs[0])
    x, y, z = position.outputs["X"], position.outputs["Y"], position.outputs["Z"]
    top = math_node(tree, "Top_face", "GREATER_THAN",
                    math_node(tree, "Absolute_normal_Y", "ABSOLUTE", normal.outputs["Y"]), 0.5)
    side = math_node(tree, "X_face", "GREATER_THAN",
                     math_node(tree, "Absolute_normal_X", "ABSOLUTE", normal.outputs["X"]), 0.5)
    side = math_node(tree, "X_face_below_top", "MULTIPLY", side,
                     math_node(tree, "Not_top", "SUBTRACT", 1.0, top))
    u = math_node(tree, "Projected_U", "ADD", x,
                  math_node(tree, "U_face_offset", "MULTIPLY", side,
                            math_node(tree, "Z_minus_X", "SUBTRACT", z, x)))
    v = math_node(tree, "Projected_V", "ADD", y,
                  math_node(tree, "V_face_offset", "MULTIPLY", top,
                            math_node(tree, "Z_minus_Y", "SUBTRACT", z, y)))
    phase = math_node(tree, "A1_diagonal", "ADD", u, math_node(tree, "A1_slope", "MULTIPLY", v, 0.36))
    phase = math_node(tree, "A1_frequency", "MULTIPLY", phase, 8.5)
    warp = math_node(tree, "A1_warp_sine", "SINE", math_node(tree, "A1_warp_frequency", "MULTIPLY", v, 4.0))
    wave = math_node(tree, "A1_wave", "ABSOLUTE",
                     math_node(tree, "A1_wave_sine", "SINE",
                               math_node(tree, "A1_warped_phase", "ADD", phase,
                                         math_node(tree, "A1_warp_amount", "MULTIPLY", warp, 0.55))))
    smooth = tree.nodes.new("ShaderNodeMapRange")
    smooth.name = "A1_original_smoothstep"
    smooth.interpolation_type = "SMOOTHSTEP"
    smooth.clamp = True
    tree.links.new(wave, smooth.inputs["Value"])
    for name, value in (("From Min", 0.18), ("From Max", 0.34), ("To Min", 0.0), ("To Max", 1.0)):
        smooth.inputs[name].default_value = value
    return math_node(tree, "A1_original_coarse", "SUBTRACT", 1.0, smooth.outputs["Result"])


def create_material(bpy, variant):
    params = REFERENCE_PARAMETERS[variant]
    material = bpy.data.materials.new(MATERIAL_NAMES[variant])
    material.use_nodes = True
    material.use_fake_user = True
    material.roughness = params["roughness"]
    material.metallic = params["metallic"]
    material.diffuse_color = tuple(channel * params["albedo_multiplier"] for channel in PALETTE[0]) + (1.0,)
    material["artifact_class"] = "MATERIAL_LIBRARY_ONLY"
    material["parameter_mapping"] = "BLENDER_REFERENCE_ONLY_NOT_GODOT_PIXEL_EQUIVALENT"
    material["authority_text"] = variant + "_AUTHORITY.gdshader"
    tree = material.node_tree
    tree.nodes.clear()
    output = tree.nodes.new("ShaderNodeOutputMaterial")
    output.name = "Surface_only_no_displacement"
    output.location = (780, 60)
    bsdf = tree.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.name = "REFERENCE_Principled"
    bsdf.label = variant + " reference settings; Godot authority in Text"
    bsdf.location = (450, 60)
    for name, value in (("Roughness", params["roughness"]), ("Metallic", params["metallic"]),
                        ("Specular IOR Level", params["specular_ior_level"]), ("Alpha", 1.0),
                        ("Transmission Weight", 0.0), ("Coat Weight", 0.0), ("Emission Strength", 0.0)):
        bsdf.inputs[name].default_value = value
    bsdf.inputs["Emission Color"].default_value = (0.0, 0.0, 0.0, 1.0)
    tree.links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
    coordinates = tree.nodes.new("ShaderNodeTexCoord")
    coordinates.name = "Object_coordinates_reference"
    factor = broadwave(tree, coordinates)
    color = tree.nodes.new("ShaderNodeMixRGB")
    color.name = "A1_palette_uniform_multiplier"
    color.label = "A1 palette x " + str(params["albedo_multiplier"])
    color.blend_type = "MIX"
    color.location = (180, 320)
    for index, endpoint in enumerate(PALETTE, start=1):
        color.inputs[index].default_value = tuple(channel * params["albedo_multiplier"] for channel in endpoint) + (1.0,)
    tree.links.new(factor, color.inputs[0])
    tree.links.new(color.outputs["Color"], bsdf.inputs["Base Color"])
    if variant == "A2":
        noise = tree.nodes.new("ShaderNodeTexNoise")
        noise.name = "A2_micro_noise"
        noise.noise_dimensions = "3D"
        noise.location = (-100, -250)
        noise.inputs["Scale"].default_value = params["micro_noise_scale"]
        noise.inputs["Detail"].default_value = 2.0
        noise.inputs["Roughness"].default_value = 0.5
        tree.links.new(coordinates.outputs["Object"], noise.inputs["Vector"])
        bump = tree.nodes.new("ShaderNodeBump")
        bump.name = "A2_micro_bump_reference"
        bump.location = (190, -180)
        bump.invert = False
        bump.inputs["Strength"].default_value = params["bump_strength"]
        bump.inputs["Distance"].default_value = params["bump_distance_blender_units"]
        tree.links.new(noise.outputs["Fac"], bump.inputs["Height"])
        tree.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    # Arrange the shared broadwave nodes into readable columns without operators.
    graph_nodes = [node for node in tree.nodes if tuple(node.location) == (0.0, 0.0)]
    for index, node in enumerate(graph_nodes):
        node.location = (-1400 + (index // 7) * 230, 700 - (index % 7) * 180)
    return material


def close_number(actual, expected, label):
    require(math.isclose(actual, expected, rel_tol=0.0, abs_tol=1e-6),
            "Reopened value differs: " + label + " " + repr(actual))


def inspect_material(bpy, variant):
    material = bpy.data.materials[MATERIAL_NAMES[variant]]
    params = REFERENCE_PARAMETERS[variant]
    tree = material.node_tree
    bsdf = tree.nodes["REFERENCE_Principled"]
    result = {"name": material.name, "fake_user": material.use_fake_user,
              "node_count": len(tree.nodes), "link_count": len(tree.links),
              "roughness": float(bsdf.inputs["Roughness"].default_value),
              "metallic": float(bsdf.inputs["Metallic"].default_value),
              "specular_ior_level": float(bsdf.inputs["Specular IOR Level"].default_value),
              "alpha": float(bsdf.inputs["Alpha"].default_value),
              "emission_strength": float(bsdf.inputs["Emission Strength"].default_value),
              "normal_linked": bsdf.inputs["Normal"].is_linked,
              "palette_endpoints": [list(tree.nodes["A1_palette_uniform_multiplier"].inputs[index].default_value)
                                    for index in (1, 2)],
              "displacement_linked": tree.nodes["Surface_only_no_displacement"].inputs["Displacement"].is_linked}
    require(result["fake_user"] and not result["displacement_linked"], "Material persistence/surface-only check failed")
    for name in ("roughness", "metallic", "specular_ior_level"):
        close_number(result[name], params[name], variant + "." + name)
    close_number(result["alpha"], 1.0, variant + ".alpha")
    close_number(result["emission_strength"], 0.0, variant + ".emission_strength")
    for actual, endpoint in zip(result["palette_endpoints"], PALETTE):
        for channel, expected in zip(actual[:3], endpoint):
            close_number(channel, expected * params["albedo_multiplier"], variant + ".palette")
        close_number(actual[3], 1.0, variant + ".palette_alpha")
    require(bsdf.inputs["Base Color"].is_linked, "Missing reference broadwave graph")
    if variant == "A2":
        bump, noise = tree.nodes["A2_micro_bump_reference"], tree.nodes["A2_micro_noise"]
        result.update({"bump_strength": float(bump.inputs["Strength"].default_value),
                       "bump_distance_blender_units": float(bump.inputs["Distance"].default_value),
                       "micro_noise_scale": float(noise.inputs["Scale"].default_value),
                       "noise_dimensions": noise.noise_dimensions, "bump_invert": bump.invert})
        for name in ("bump_strength", "bump_distance_blender_units", "micro_noise_scale"):
            close_number(result[name], params[name], variant + "." + name)
        require(result["normal_linked"] and bump.inputs["Height"].is_linked and not bump.invert,
                "Missing micro bump reference links")
    else:
        require(not result["normal_linked"], "A1 must not gain a normal/bump effect")
    return result


def main():
    output, receipt_path, identity, shader_texts = preflight()
    import bpy

    require(bpy.app.background, "Background Blender process required")
    bpy.context.preferences.filepaths.save_version = 0
    bpy.context.preferences.filepaths.use_scripts_auto_execute = False
    # Remove only this fresh process's factory defaults. Never author geometry.
    for objects in (bpy.data.objects, bpy.data.meshes, bpy.data.cameras, bpy.data.lights,
                    bpy.data.materials, bpy.data.texts, bpy.data.worlds):
        for block in tuple(objects):
            objects.remove(block, do_unlink=True)
    require(len(bpy.data.objects) == 0 and len(bpy.data.meshes) == 0, "Factory geometry removal failed")
    scene = bpy.context.scene
    scene.unit_settings.system = "NONE"
    scene.unit_settings.scale_length = 1.0
    scene["artifact_class"] = "MATERIAL_LIBRARY_ONLY"
    scene["original_source_blend"] = False
    scene["model_preview"] = False
    for variant in ("A1", "A2"):
        create_material(bpy, variant)
    texts = {"README_MATERIAL_LIBRARY.txt": README,
             "SOURCE_IDENTITY.json": json.dumps(identity, ensure_ascii=False, indent=2) + "\n", **shader_texts}
    for name, value in texts.items():
        text = bpy.data.texts.new(name)
        text.from_string(value)
        text.use_fake_user = True
    for variant in ("A1", "A2"):
        inspect_material(bpy, variant)
    require(len(bpy.data.objects) == 0 and len(bpy.data.meshes) == 0, "Geometry unexpectedly present")
    require(not output.exists() and not receipt_path.exists(), "Output appeared during authoring; refusing overwrite")
    result = bpy.ops.wm.save_as_mainfile(filepath=str(output), check_existing=True)
    require(result == {"FINISHED"} and output.is_file(), "Blender save did not finish")
    saved_sha = sha256(output)
    result = bpy.ops.wm.open_mainfile(filepath=str(output), load_ui=False, use_scripts=False)
    require(result == {"FINISHED"}, "Blender reopen did not finish")
    require(Path(bpy.data.filepath).resolve() == output, "Reopened a different Blender file")
    require(len(bpy.data.objects) == 0 and len(bpy.data.meshes) == 0, "Reopened file contains geometry")
    require(set(bpy.data.materials.keys()) == set(MATERIAL_NAMES.values()), "Unexpected reopened materials")
    for name, expected in texts.items():
        require(bpy.data.texts[name].as_string() == expected, "Reopened source text differs: " + name)
    close_number(bpy.context.scene.unit_settings.scale_length, 1.0, "scene.unit_scale")
    require(bpy.context.scene.unit_settings.system == "NONE", "Unexpected reopened unit system")
    materials = {variant: inspect_material(bpy, variant) for variant in ("A1", "A2")}
    for row in identity["files"]:
        require(sha256(row["path"]) == row["sha256"], "Read-only source changed: " + row["path"])
    require(sha256(output) == saved_sha, "Reopen changed saved file bytes")
    require(not Path(str(output) + "1").exists() and not Path(str(output) + "2").exists(), "Unexpected Blender backup")
    binary = Path(bpy.app.binary_path).resolve()
    decode = lambda value: value.decode("utf-8", "replace") if isinstance(value, bytes) else str(value)
    receipt = {
        "status": "PASS", "artifact_class": "MATERIAL_LIBRARY_ONLY",
        "source_blend_status": "NOT_ORIGINAL_SOURCE_BLEND", "preview_status": "NOT_A_BLENDER_MODEL_PREVIEW",
        "completed_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "blend_path": str(output), "blend_sha256": saved_sha, "blend_bytes": output.stat().st_size,
        "reopened_in_same_background_process": True, "objects": len(bpy.data.objects),
        "meshes": len(bpy.data.meshes), "cameras": len(bpy.data.cameras), "lights": len(bpy.data.lights),
        "blender_version": bpy.app.version_string, "blender_version_tuple": list(bpy.app.version),
        "blender_build_hash": decode(bpy.app.build_hash), "blender_build_date": decode(bpy.app.build_date),
        "blender_build_time": decode(bpy.app.build_time), "blender_binary": str(binary),
        "blender_binary_sha256": sha256(binary), "background": bpy.app.background,
        "unit_system": bpy.context.scene.unit_settings.system,
        "scene_unit_scale": bpy.context.scene.unit_settings.scale_length,
        "materials": materials, "text_sha256": {name: text_sha256(bpy.data.texts[name].as_string()) for name in texts},
        "source_identity": identity, "source_preservation": "PASS",
        "blender_rendering": "NOT_RUN", "godot_pixel_equivalence": "NOT_CLAIMED",
        "model_delivery": "NOT_DELIVERED_MATERIAL_LIBRARY_ONLY", "command_line": list(sys.argv),
    }
    with receipt_path.open("x", encoding="utf-8", newline="\n") as stream:
        stream.write(json.dumps(receipt, ensure_ascii=False, indent=2) + "\n")
    print("MATERIAL_LIBRARY_REOPEN PASS objects=0 meshes=0 blend_sha256=" + saved_sha)


if __name__ == "__main__":
    main()
