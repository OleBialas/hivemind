from pathlib import Path
import numpy as np
from scipy.io import loadmat, savemat
from mne.io import RawArray
from mne import create_info
from mne.channels import make_standard_montage
from mne.preprocessing import ICA, read_ica, corrmap
from pyprep.ransac import find_bad_by_ransac
from meegkit.dss import dss_line
from meegkit.detrend import detrend

root = Path(__file__).parent.parent.absolute()
data_dir = root / "input" / "raw"
out_dir = root / "input" / "preprocessed"
montage = make_standard_montage("biosemi128")
info = create_info(ch_names=montage.ch_names, sfreq=128, ch_types="eeg")
reference_ica = read_ica(root / "code" / "reference-ica.fif")
for sub_folder_in in data_dir.glob("sub*"):
    sub_folder_out = out_dir / sub_folder_in.name
    if not sub_folder_out.exists():
        sub_folder_out.mkdir()
    for matfile in sub_folder_in.glob("*.mat"):
        mat = loadmat(matfile)
        # Reference to mastoids average
        data = mat["eegData"] - mat["mastoids"].mean(axis=1, keepdims=True)
        data /= 1e6  # convert to V
        data = np.expand_dims(data, axis=2)
        # remove power line noise
        data, _ = dss_line(data, fline=50, sfreq=info["sfreq"], nremove=5)
        data, _, _ = detrend(data, 5)
        raw = RawArray(data.squeeze().T, info)
        raw.set_eeg_reference([])  # mark data as referenced
        raw.set_montage(montage)
        # blink removal with ICA
        ica = ICA(n_components=100)
        ica.fit(raw)
        corrmap([reference_ica, ica], template=(0, 0), show=False, label="blinks")
        raw = ica.apply(raw, exclude=ica.labels_["blinks"])
        bads, _ = find_bad_by_ransac(
            raw.get_data(),
            sample_rate=128,
            exclude=[],
            complete_chn_labs=np.array(raw.info["ch_names"]),
            chn_pos=np.stack([r["loc"][0:3] for r in raw.info["chs"]]),
        )
        raw.info["bads"] = bads
        raw = raw.interpolate_bads()
        # save results
        raw.save(sub_folder_out / f"{matfile.name[:-4]}-raw.fif", overwrite=True)
        ica.save(sub_folder_out / f"{matfile.name[:-4]}-ica.fif", overwrite=True)

        mat = {
            "eegData": raw.get_data().T,
            "chNames": raw.info["ch_names"],
            "reference": "linked mastoids",
            "fs": raw.info["sfreq"],
            "chCoords": np.stack([r["loc"][0:3] for r in raw.info["chs"]]),
        }
        savemat(sub_folder_out / matfile.name, mat)
