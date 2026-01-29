output "id" {
  value = [for bucket in oci_objectstorage_bucket.buckets : bucket.id]
}