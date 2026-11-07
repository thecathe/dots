# The Parakeet speech model voxtype transcribes with, as store paths: one
# directory per variant, in the layout voxtype wants (`parakeet.model` takes such
# a directory).
#
# Nothing here is downloaded until a variant is actually used by a build. The
# files come from Hugging Face's istupakov/parakeet-tdt-0.6b-v2-onnx (an ONNX
# export of NVIDIA's English-only Parakeet TDT 0.6B v2, CC-BY-4.0, ungated) at a
# pinned commit, each by the SHA-256 Hugging Face itself lists for it (the LFS
# `oid` in the repository's tree listing; the two small non-LFS files, vocab.txt
# and config.json, were hashed after download and their git blob ids matched the
# listing). Nix refuses a file that does not match.
#
# Two variants, because they differ in speed and size:
#   fp32  encoder-model.onnx (42 MB graph) + encoder-model.onnx.data (2.4 GB of
#         weights), decoder 36 MB. 2.5 GB. The full-precision model, and the only
#         one the GPU build can use well.
#   int8  the same network quantised to 8 bits: encoder 652 MB, decoder 9 MB.
#         0.66 GB, meant for the CPU.
# They are separate directories, not one with everything in it, because voxtype's
# loader (parakeet-rs `find_encoder`) takes `encoder-model.onnx` first when it is
# present, so a directory holding both would always run fp32.
#
# The encoder's weights are "external data": encoder-model.onnx names
# encoder-model.onnx.data, and ONNX Runtime looks for it beside the graph file.
# The directory is therefore assembled from symlinks into the per-file store
# paths (no 2.4 GB copy). Whether ONNX Runtime accepts external data behind a
# symlink is not something to assume; see the devlog entry for what was measured.
{
  fetchurl,
  linkFarm,
}: let
  repo = "istupakov/parakeet-tdt-0.6b-v2-onnx";
  rev = "0bbb45a3365852604aef28b538a8f066f4ccaa85";

  fetch = file: hash:
    fetchurl {
      name = "parakeet-tdt-0.6b-v2-${file}";
      url = "https://huggingface.co/${repo}/resolve/${rev}/${file}";
      inherit hash;
    };

  files = {
    "vocab.txt" = fetch "vocab.txt" "sha256-7BgrcN1CETr/bFNyx1ysWMlSRD6yIyL1e71/U5d9SX0=";
    "encoder-model.onnx" = fetch "encoder-model.onnx" "sha256-OYe80oF12CnRKIiplqhOj2Kg43TZ/9ZAZiwVFa3GedM=";
    "encoder-model.onnx.data" = fetch "encoder-model.onnx.data" "sha256-TatzYtSHTYWWUEWx5BstYd0swPslZxp/az3Ee/EgzEE=";
    "decoder_joint-model.onnx" = fetch "decoder_joint-model.onnx" "sha256-y7UqB71wq1tn+EOdSzzYcEsYRntEMLysta2r4VS40ZE=";
    "encoder-model.int8.onnx" = fetch "encoder-model.int8.onnx" "sha256-PgWB/aarhDiItR5W1+54ttW8MjfsETrx9zLR1ShqoVU=";
    "decoder_joint-model.int8.onnx" = fetch "decoder_joint-model.int8.onnx" "sha256-pEn0ms1ol51BhlHdLctzfMDxvwIl4AninuMmNU7b99M=";
  };

  directory = name: names:
    linkFarm name (map (file: {
        name = file;
        path = files.${file};
      })
      names);
in {
  v2 = directory "parakeet-tdt-0.6b-v2" [
    "vocab.txt"
    "encoder-model.onnx"
    "encoder-model.onnx.data"
    "decoder_joint-model.onnx"
  ];
  v2-int8 = directory "parakeet-tdt-0.6b-v2-int8" [
    "vocab.txt"
    "encoder-model.int8.onnx"
    "decoder_joint-model.int8.onnx"
  ];
}
