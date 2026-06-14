import os
import random
import shutil
import argparse
import uuid
from pathlib import Path
from PIL import Image

def prepare_yolo_dataset(
    ingest_dir: str,
    output_dir: str,
    target_size: int = 640,
    weights: tuple = (0.8, 0.2, 0.0)  # Train, Val, Test
):
    ingest_path = Path(ingest_dir)
    output_path = Path(output_dir)
    
    # Supported image extensions
    valid_extensions = {'.jpg', '.jpeg', '.png', '.bmp', '.webp'}
    images = [f for f in ingest_path.iterdir() if f.suffix.lower() in valid_extensions]
    
    if not images:
        print("No valid images found.")
        return

    random.shuffle(images)
    
    # Split Math
    total = len(images)
    train_end = int(total * weights[0])
    val_end = train_end + int(total * weights[1])
    
    splits = {
        'Train': images[:train_end],
        'Val': images[train_end:val_end],
        'Test': images[val_end:] if weights[2] > 0 else []
    }

    # Process Splits
    for split_name, split_images in splits.items():
        if not split_images:
            continue
            
        # YOLO Specific Subfolders: split/images and split/labels
        img_dir = output_path / split_name / "images"
        lbl_dir = output_path / split_name / "labels"
        
        img_dir.mkdir(parents=True, exist_ok=True)
        lbl_dir.mkdir(parents=True, exist_ok=True)

        for img_path in split_images:
            # 1. Resize and Save Image
            try:
                with Image.open(img_path) as img:
                    img.thumbnail((target_size, target_size))
                    img.save(img_dir / img_path.name)
                
                # 2. Check for an existing label file in the ingest folder
                # (Assumes label file has the same name but .txt extension)
                corresponding_label = img_path.with_suffix('.txt')
                dest_label_path = lbl_dir / corresponding_label.name
                
                if corresponding_label.exists():
                    shutil.copy(corresponding_label, dest_label_path)
                else:
                    # Create an empty label file if none exists (signifies background image)
                    open(dest_label_path, 'a').close()
                    
            except Exception as e:
                print(f"Error processing {img_path.name}: {e}")

    # 4. Generate YOLO-compliant YAML File
    yaml_content = f"""# Path configuration
path: {output_path}  # dataset root dir
train: Train/images          # train images (relative to 'path')
val: Val/images              # val images (relative to 'path')
test: {f"Test/images" if weights[2] > 0 else ""}  # {'NOT REQUIRED FOR SYNTHS IMAGES' if weights[2] == 0 else ''}

nc: 1
names: ['sapatilha']

"""
    
    with open(output_path / "dataset.yaml", "w") as f:
        f.write(yaml_content.strip())
        
    print(f"YOLO Dataset ready at: {output_path}")

if __name__ == "__main__":
    # 1. Initialize the argument parser
    parser = argparse.ArgumentParser(description="Prepare and split image datasets for YOLO training.")
    guid_suffix = str(uuid.uuid4())[:4]
    # 2. Define the arguments
    parser.add_argument(
        "--ingest_dir", 
        type=str, 
        default="./raw_incoming_images", 
        help="Path to the folder containing raw images and labels."
    )
    parser.add_argument(
        "--output_dir", 
        type=str, 
        default=f"./Datasets/{guid_suffix}", 
        help="Path where the structured YOLO dataset will be saved."
    )
    parser.add_argument(
        "--target_size", 
        type=int, 
        default=640, 
        help="Target size to resize the largest side of the image to."
    )
    parser.add_argument(
        "--weights", 
        type=float, 
        nargs=3, 
        default=[0.8, 0.2, 0.0], 
        help="Three space-separated float values for Train, Val, and Test split fractions (e.g., 0.7 0.2 0.1)."
    )

    # 3. Parse the command-line inputs
    args = parser.parse_args()

    # 4. Convert weights list to a tuple and call your function
    prepare_yolo_dataset(
        ingest_dir=args.ingest_dir,
        output_dir=args.output_dir,
        target_size=args.target_size,
        weights=tuple(args.weights)
    )

    print(f"Task complete, Output location: {args.output_dir}")