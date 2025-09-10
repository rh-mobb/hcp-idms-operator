// Copyright 2024 Red Hat, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// ImageMirrorDigestSetSpec defines the desired state of ImageMirrorDigestSet
type ImageMirrorDigestSetSpec struct {
	// Mirrors defines the registry mirrors for this set
	Mirrors []RegistryMirror `json:"mirrors"`
}

// RegistryMirror defines a registry mirror configuration
type RegistryMirror struct {
	// Source is the source registry URL
	Source string `json:"source"`
	// Mirrors is a list of mirror URLs for the source registry
	Mirrors []string `json:"mirrors"`
	// InsecureSkipTLSVerify indicates whether to skip TLS verification
	InsecureSkipTLSVerify bool `json:"insecureSkipTLSVerify,omitempty"`
}

// ImageMirrorDigestSetStatus defines the observed state of ImageMirrorDigestSet
type ImageMirrorDigestSetStatus struct {
	// Conditions represent the latest available observations of the object's state
	Conditions []metav1.Condition `json:"conditions,omitempty"`
	// ObservedGeneration is the generation of the resource that was last processed
	ObservedGeneration int64 `json:"observedGeneration,omitempty"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:resource:scope=Cluster
// +kubebuilder:printcolumn:name="Age",type="date",JSONPath=".metadata.creationTimestamp"

// ImageMirrorDigestSet is the Schema for the imagemirrordigestsets API
type ImageMirrorDigestSet struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   ImageMirrorDigestSetSpec   `json:"spec,omitempty"`
	Status ImageMirrorDigestSetStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

// ImageMirrorDigestSetList contains a list of ImageMirrorDigestSet
type ImageMirrorDigestSetList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []ImageMirrorDigestSet `json:"items"`
}

func init() {
	SchemeBuilder.Register(&ImageMirrorDigestSet{}, &ImageMirrorDigestSetList{})
}
