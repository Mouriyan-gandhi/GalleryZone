"use client";

import * as React from "react";
import {
  FaCloudUploadAlt,
  FaFileAlt,
  FaFileImage,
  FaFilePdf,
  FaFileWord,
  FaSpinner,
  FaTimes,
  FaCheckCircle,
  FaExclamationCircle,
  FaShieldAlt,
  FaArrowRight,
} from "react-icons/fa";
import {
  Card,
  CardContent,
  CardFooter,
  CardHeader,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { cn } from "@/lib/utils";

export type FileStatus = "queued" | "uploading" | "done" | "error";

export interface UploadedFile {
  id: string;
  file: File;
  progress: number;
  status: FileStatus;
}

export interface FileUploaderProps {
  title?: string;
  description?: string;
  acceptedFormats?: string[];
  maxFiles?: number;
  maxSizeMB?: number;
  submitLabel?: string;
  cancelLabel?: string;
  onSubmit?: (files: File[]) => void;
  onCancel?: () => void;
  className?: string;
}

function generateId(): string {
  return Math.random().toString(36).slice(2, 9);
}

function formatFileSize(bytes: number): string {
  if (bytes >= 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} mb`;
  return `${Math.max(1, Math.round(bytes / 1024))} kb`;
}

function getExtension(fileName: string): string {
  return fileName.split(".").pop()?.toLowerCase() ?? "";
}

function FileTypeIcon({ extension }: { extension: string }) {
  if (["jpg", "jpeg", "png", "svg", "gif", "webp"].includes(extension))
    return <FaFileImage className="size-4" />;
  if (extension === "pdf") return <FaFilePdf className="size-4" />;
  if (["doc", "docx"].includes(extension))
    return <FaFileWord className="size-4" />;
  return <FaFileAlt className="size-4" />;
}

// Content/copy (title, empty state, format + size helper lines) matches the
// requested reference exactly, except the size limits: the source demo's
// "24GB max / 20MB min" were placeholder numbers that would reject nearly
// every real photo or scan. Real limits here instead (10MB per file, no
// minimum -- there's no reason to reject a small, valid document).
export function FileUploader({
  title = "Upload Files",
  description,
  acceptedFormats = ["jpg", "pdf", "svg", "png", "docx"],
  maxFiles = 5,
  maxSizeMB = 10,
  submitLabel = "Submit",
  cancelLabel = "Clear all",
  onSubmit,
  onCancel,
  className,
}: FileUploaderProps) {
  const [files, setFiles] = React.useState<UploadedFile[]>([]);
  const [isDragging, setIsDragging] = React.useState(false);
  const inputRef = React.useRef<HTMLInputElement>(null);
  const dragCounter = React.useRef(0);

  const accept = acceptedFormats.map((format) => `.${format}`).join(",");
  const acceptedSet = React.useMemo(
    () => new Set(acceptedFormats.map((f) => f.toLowerCase())),
    [acceptedFormats],
  );

  const hasUploadingFiles = files.some(
    (f) => f.status === "uploading" || f.status === "queued",
  );
  const allDone = files.length > 0 && files.every((f) => f.status === "done");
  const isAtLimit = files.length >= maxFiles;
  const totalSize = files.reduce((total, f) => total + f.file.size, 0);

  React.useEffect(() => {
    if (!hasUploadingFiles) return;

    const interval = window.setInterval(() => {
      setFiles((current) =>
        current.map((f) => {
          if (f.status !== "uploading" && f.status !== "queued") return f;
          const nextProgress = Math.min(
            f.progress + 8 + Math.random() * 14,
            100,
          );
          return {
            ...f,
            progress: nextProgress,
            status: nextProgress >= 100 ? "done" : "uploading",
          };
        }),
      );
    }, 350);

    return () => window.clearInterval(interval);
  }, [hasUploadingFiles]);

  function addFiles(incoming: FileList | File[]) {
    const maxBytes = maxSizeMB * 1024 * 1024;
    const remaining = maxFiles - files.length;

    const toAdd: UploadedFile[] = Array.from(incoming)
      .slice(0, Math.max(0, remaining))
      .map((file) => {
        const extension = getExtension(file.name);
        const isAccepted = !acceptedSet.size || acceptedSet.has(extension);
        const isTooLarge = file.size > maxBytes;
        return {
          id: generateId(),
          file,
          progress: 0,
          status:
            isAccepted && !isTooLarge
              ? ("queued" as const)
              : ("error" as const),
        };
      });

    setFiles((current) => [...current, ...toAdd]);
  }

  function removeFile(id: string) {
    setFiles((current) => current.filter((f) => f.id !== id));
  }

  function clearAll() {
    setFiles([]);
    if (inputRef.current) inputRef.current.value = "";
  }

  function handleDragEnter(e: React.DragEvent) {
    e.preventDefault();
    dragCounter.current += 1;
    setIsDragging(true);
  }

  function handleDragLeave(e: React.DragEvent) {
    e.preventDefault();
    dragCounter.current -= 1;
    if (dragCounter.current === 0) setIsDragging(false);
  }

  function handleDrop(e: React.DragEvent) {
    e.preventDefault();
    dragCounter.current = 0;
    setIsDragging(false);
    if (e.dataTransfer.files.length) addFiles(e.dataTransfer.files);
  }

  function handleSubmit() {
    onSubmit?.(files.filter((f) => f.status === "done").map((f) => f.file));
  }

  return (
    <Card className={cn("mx-auto w-full max-w-xl ring-0 shadow-lg", className)}>
      <CardHeader>
        <div className="flex items-start justify-between gap-3">
          <div className="flex flex-col gap-1">
            <h2 className="text-xl font-normal tracking-tight text-foreground">
              {title}
            </h2>
            {description && (
              <p className="text-sm leading-relaxed text-muted-foreground">
                {description}
              </p>
            )}
          </div>
          {files.length > 0 && (
            <Badge variant="secondary" className="shrink-0 tabular-nums">
              {files.length}&nbsp;/&nbsp;{maxFiles}
            </Badge>
          )}
        </div>
      </CardHeader>

      <CardContent className="flex flex-col gap-5">
        {!isAtLimit && (
          <div className="flex flex-col gap-2">
            <div
              role="button"
              tabIndex={0}
              onClick={() => inputRef.current?.click()}
              onKeyDown={(e) => {
                if (e.key === "Enter" || e.key === " ") {
                  e.preventDefault();
                  inputRef.current?.click();
                }
              }}
              onDragEnter={handleDragEnter}
              onDragOver={(e) => e.preventDefault()}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
              className={cn(
                "flex w-full flex-col items-center justify-center gap-1 rounded-xl border-2 border-dashed border-border bg-muted/30 py-10 text-center transition-colors focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none",
                isDragging
                  ? "border-primary bg-primary/5"
                  : "hover:border-primary/50 hover:bg-muted/50",
              )}
            >
              <FaCloudUploadAlt
                className={cn(
                  "mb-3 size-10 transition-colors",
                  isDragging ? "text-primary" : "text-muted-foreground/40",
                )}
              />
              <span className="text-base font-medium text-foreground">
                {isDragging ? "Release to add files" : "Drag files to upload"}
              </span>
              <span className="my-3 flex items-center gap-3 text-xs text-muted-foreground italic before:h-px before:w-10 before:bg-border after:h-px after:w-10 after:bg-border">
                or select a file
              </span>
              <Button
                type="button"
                size="sm"
                onClick={(e) => {
                  e.stopPropagation();
                  inputRef.current?.click();
                }}
              >
                Choose File
              </Button>
            </div>

            <input
              ref={inputRef}
              type="file"
              multiple
              accept={accept}
              className="sr-only"
              onChange={(e) => {
                if (e.target.files) addFiles(e.target.files);
                e.target.value = "";
              }}
            />

            <p className="text-[11px] leading-relaxed text-muted-foreground">
              Acceptable formats: {acceptedFormats.join(", ")}
              <br />
              Max file size is {maxSizeMB}MB per file
            </p>
          </div>
        )}

        <div>
          <div className="mb-2 flex items-center gap-2 text-sm font-semibold text-foreground">
            {hasUploadingFiles && (
              <FaSpinner className="size-3.5 animate-spin text-muted-foreground" />
            )}
            <span>{hasUploadingFiles ? "Uploading..." : "Files"}</span>
          </div>

          {files.length === 0 ? (
            <div className="flex h-32 flex-col items-center justify-center rounded-lg border border-dashed border-border bg-muted/20 text-center">
              <p className="text-sm font-medium text-foreground">
                No files selected
              </p>
              <p className="mt-1 text-xs text-muted-foreground">
                Uploaded files will appear here.
              </p>
            </div>
          ) : (
            <div className="flex flex-col gap-2">
              {files.map((f) => {
                const extension = getExtension(f.file.name);
                const inProgress =
                  f.status === "uploading" || f.status === "queued";

                return (
                  <div
                    key={f.id}
                    className="flex flex-col gap-2 rounded-lg border border-border bg-muted/40 px-3 py-2.5"
                  >
                    <div className="flex items-center gap-3">
                      <span
                        className={cn(
                          "shrink-0",
                          f.status === "error"
                            ? "text-destructive"
                            : f.status === "done"
                              ? "text-primary"
                              : "text-muted-foreground",
                        )}
                      >
                        <FileTypeIcon extension={extension} />
                      </span>

                      <div className="flex min-w-0 flex-1 flex-col gap-0.5">
                        <p className="truncate text-sm font-medium text-foreground">
                          {f.file.name}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          {formatFileSize(f.file.size)}
                        </p>
                      </div>

                      <div className="flex shrink-0 items-center gap-2">
                        {f.status === "done" && (
                          <FaCheckCircle className="size-3.5 text-primary" />
                        )}
                        {f.status === "error" && (
                          <FaExclamationCircle className="size-3.5 text-destructive" />
                        )}
                        {inProgress && (
                          <span className="text-xs tabular-nums text-muted-foreground">
                            {Math.round(f.progress)}%
                          </span>
                        )}
                        <button
                          type="button"
                          aria-label={`Remove ${f.file.name}`}
                          onClick={() => removeFile(f.id)}
                          className="text-muted-foreground transition-colors hover:text-destructive"
                        >
                          <FaTimes className="size-3.5" />
                        </button>
                      </div>
                    </div>

                    {inProgress && (
                      <Progress
                        value={f.progress}
                        className="h-1 [&_[data-slot=progress-indicator]]:bg-chart-1"
                      />
                    )}
                    {f.status === "error" && (
                      <p className="text-xs text-destructive">
                        Unsupported format or file too large.
                      </p>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {files.length > 0 && (
          <div className="flex items-center justify-between">
            <span className="text-xs text-muted-foreground">
              {files.length} file{files.length !== 1 ? "s" : ""}
              &nbsp;·&nbsp;{formatFileSize(totalSize)} total
            </span>
            {!hasUploadingFiles && (
              <button
                type="button"
                onClick={clearAll}
                className="text-xs text-muted-foreground transition-colors hover:text-foreground"
              >
                {cancelLabel}
              </button>
            )}
          </div>
        )}
      </CardContent>

      <CardFooter className="flex flex-col items-stretch gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-1.5 text-muted-foreground">
          <FaShieldAlt className="size-3" />
          <span className="text-xs">Encrypted in transit</span>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={onCancel ?? clearAll}
            className="flex-1 sm:flex-none"
          >
            Cancel
          </Button>
          <Button
            size="sm"
            disabled={!allDone}
            onClick={handleSubmit}
            className="flex-1 gap-1.5 sm:flex-none"
          >
            {submitLabel}
            <FaArrowRight className="size-3" />
          </Button>
        </div>
      </CardFooter>
    </Card>
  );
}

export default FileUploader;
